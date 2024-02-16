import {
  sum,
  div,
  addToCallback,
  CircuitValue,
  CircuitValue256,
  constant,
  witness,
  getAccount,
  mul,
  add,
  checkLessThan,
  getReceipt,
  checkEqual,
  getSolidityMapping,
  mulAdd,
  log,
  selectFromIdx,
  sub,
  isLessThan,
  isZero,
  or,
  assertBit,
  assertIsConst
} from "@axiom-crypto/client";

/// For type safety, define the input types to your circuit here.
/// These should be the _variable_ inputs to your circuit. Constants can be hard-coded into the circuit itself.
export interface CircuitInputs {
  blockNumbers: CircuitValue[];
  txIdxs: CircuitValue[];
  logIdxs: CircuitValue[];
  numClaims: CircuitValue;
}

export const defaultInputs = {
    blockNumbers: [5141171, 5141525, 5141525, 5141525, 5141525, 5141525, 5141525, 5141525, 5141525, 5141525],
    txIdxs: [62, 62, 62, 62, 62, 62, 62, 62, 62, 62],
    logIdxs: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    numClaims: 2
};

export const circuit = async ({
  blockNumbers,
  txIdxs,
  logIdxs,
  numClaims
}: CircuitInputs) => {
  const MAX_CLAIMS = 10;
  const AXIOM_REFERRAL_ADDRESS = "0x9698a5f9e16CA04FBcF61468d3FdBfF515741D76";
  const REFERRER_MAPPING_SLOT = 3;

  const CLAIM_ADDRESS = "0x9698a5f9e16CA04FBcF61468d3FdBfF515741D76";
  const EVENT_SCHEMA = "0x2c76e7a47fd53e2854856ac3f0a5f3ee40d15cfaa82266357ea9779c486ab9c3";

  let numClaimsVal = Number(numClaims.value());
  if (numClaimsVal > MAX_CLAIMS) {
    throw new Error("Too many claims");
  }
  checkLessThan(numClaims, constant(MAX_CLAIMS + 1));
  checkLessThan(constant(0), numClaims);

  if (blockNumbers.length !== MAX_CLAIMS || txIdxs.length !== MAX_CLAIMS || logIdxs.length !== MAX_CLAIMS) {
    throw new Error("Incorrect number of claims (make sure every array has `numClaims` claims)");
  }

  for (let i = numClaimsVal; i < MAX_CLAIMS; i++) {
    blockNumbers.push(blockNumbers[numClaimsVal - 1]);
    txIdxs.push(txIdxs[numClaimsVal - 1]);
    logIdxs.push(logIdxs[numClaimsVal - 1]);
  }

  let claimIds: CircuitValue[] = [];
  let inRange: CircuitValue[] = [];
  for (let i = 0; i < MAX_CLAIMS; i++) {
    const id_1 = mulAdd(blockNumbers[i], BigInt(2 ** 64), txIdxs[i]);
    const id = mulAdd(id_1, BigInt(2 ** 64), logIdxs[i]);
    const isInRange = isLessThan(i, numClaims, "20");
    inRange.push(isInRange);
    const idOrZero = mul(id, isInRange);
    claimIds.push(idOrZero);
  }
  const lastClaimId = selectFromIdx(claimIds, sub(numClaims, constant(1)));

  for (let i = 1; i < MAX_CLAIMS; i++) {
    const isLess = isLessThan(claimIds[i - 1], claimIds[i]);
    const isLessOrZero = or(isLess, isZero(claimIds[i]));
    checkEqual(isLessOrZero, 1);
  }

  let claimAmount = constant(0);
  let referrer = constant(0);
  for (let i = 0; i < MAX_CLAIMS; i++) {
    // make sure all claims come from the correct address
    let claimAddress = (await getReceipt(blockNumbers[i], txIdxs[i]).log(logIdxs[i]).address()).toCircuitValue();
    checkEqual(CLAIM_ADDRESS, claimAddress);

    // extract the referrer for this claim
    let referee = (await getReceipt(blockNumbers[i], txIdxs[i]).log(logIdxs[i]).data(0, EVENT_SCHEMA));
    let claimReferrer = (await getSolidityMapping(blockNumbers[i], AXIOM_REFERRAL_ADDRESS, REFERRER_MAPPING_SLOT).key(referee)).toCircuitValue();

    // extract the amount for this claim
    let amount = await getReceipt(blockNumbers[i], txIdxs[i]).log(logIdxs[i]).data(4);
    let amountOrZero = mul(amount.toCircuitValue(), inRange[i]);

    if (i == 0) {
      referrer = claimReferrer;
    } else {
      checkEqual(referrer, claimReferrer);
    }

    claimAmount = add(claimAmount, amountOrZero);
  }

  addToCallback(claimIds[0]);
  addToCallback(lastClaimId);
  addToCallback(referrer);
  addToCallback(claimAmount);
};
