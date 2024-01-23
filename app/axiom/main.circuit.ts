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

const MAX_CLAIMS = 3;
const REFERRAL_ADDRESS = "0x9698a5f9e16CA04FBcF61468d3FdBfF515741D76";
const REFERRAL_MAPPING_SLOT = 3;

/// For type safety, define the input types to your circuit here.
/// These should be the _variable_ inputs to your circuit. Constants can be hard-coded into the circuit itself.
export interface CircuitInputs {
  blockNumbers: CircuitValue[];
  txIdxs: CircuitValue[];
  logIdxs: CircuitValue[];
  referrer: CircuitValue;
  numClaims: CircuitValue;
}

export const circuit = async ({
  blockNumbers,
  txIdxs,
  logIdxs,
  referrer,
  numClaims
}: CircuitInputs) => {

  let numClaimsVal = Number(numClaims.value());
  if (numClaimsVal > MAX_CLAIMS) {
    throw new Error("Too many claims");
  }

  if (blockNumbers.length !== numClaimsVal || txIdxs.length !== numClaimsVal || logIdxs.length !== numClaimsVal) {
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

  for (let i = 1; i < MAX_CLAIMS; i++) {
    // checkLessThan(add(claimIds[i - 1], i - 1), add(claimIds[i], i));
    const isLess = isLessThan(claimIds[i - 1], claimIds[i]);
    const isLessOrZero = or(isLess, isZero(claimIds[i]));
    assertIsConst(isLessOrZero, 1);
  }

  let tradeVolume = witness(0);

  for (let i = 0; i < MAX_CLAIMS; i++) {
    let trader = (await getReceipt(blockNumbers[i], txIdxs[i]).log(logIdxs[i]).data(0));
    let traderReferrer = (await getSolidityMapping(blockNumbers[i], REFERRAL_ADDRESS, REFERRAL_MAPPING_SLOT).key(trader)).toCircuitValue();
    checkEqual(referrer, traderReferrer);
    let amount = await getReceipt(blockNumbers[i], txIdxs[i]).log(logIdxs[i]).data(4);
    tradeVolume = add(tradeVolume, amount.toCircuitValue());
  }

  const lastClaimId = selectFromIdx(claimIds, sub(numClaims, constant(1)));

  addToCallback(claimIds[0]);
  addToCallback(lastClaimId);
  addToCallback(referrer);
  addToCallback(tradeVolume);
};
