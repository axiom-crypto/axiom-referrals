// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@axiom-crypto/axiom-std/AxiomTest.sol";

import { AxiomReferral } from "../src/AxiomReferral.sol";

contract AxiomReferralTest is AxiomTest {
    using Axiom for Query;

    AxiomReferral public axiomReferral;

    struct AxiomInput {
        uint64[] blockNumbers;
        uint64[] txIdxs;
        uint64[] logIdxs;
        uint64 numClaims;
    }

    AxiomInput public input;
    bytes32 public querySchema;

    event Claim(address indexed referrer, uint256 startClaimId, uint256 endClaimId, uint256 claimAmount);

    function setUp() public {
        _createSelectForkAndSetupAxiom("sepolia", 5_141_172);

        uint64[] memory blockNumbers = new uint64[](10);
        blockNumbers[0] = 5_141_171;
        blockNumbers[1] = 5_141_525;
        uint64[] memory txIdxs = new uint64[](10);
        txIdxs[0] = 62;
        txIdxs[1] = 62;
        uint64[] memory logIdxs = new uint64[](10);
        logIdxs[0] = 0;
        logIdxs[1] = 0;

        for (uint64 i = 2; i < 10; i++) {
            blockNumbers[i] = 5_141_171;
            txIdxs[i] = 62;
            logIdxs[i] = 0;
        }
        input = AxiomInput({ blockNumbers: blockNumbers, txIdxs: txIdxs, logIdxs: logIdxs, numClaims: 2 });
        querySchema = axiomVm.readCircuit("app/axiom/main.circuit.ts");

        bytes32[] memory querySchemas = new bytes32[](1);
        querySchemas[0] = querySchema;
        axiomReferral = new AxiomReferral(axiomV2QueryAddress, querySchemas);
    }

    function test_referral() public {
        Query memory q = query(querySchema, abi.encode(input), address(axiomReferral));

        // Send the query to AxiomV2Query
        q.send();

        // Prank fulfillment from Axiom, specifying `UNI_SENDER_ADDR` as the sender of the query

        // TODO: implement prankFulfill to deal with verifying emitted events
        /*
        vm.expectEmit();
        emit Claim(
            address(uint160(uint256(args.axiomResults[2]))),
            uint256(args.axiomResults[0]),
            uint256(args.axiomResults[1]),
            uint256(args.axiomResults[3])
        );
        */
        bytes32[] memory results = q.prankFulfill();

        require(
            axiomReferral.lastClaimedId(querySchema, uint256(results[2])) == uint256(results[1]),
            "Last claim ID not updated"
        );
    }
}
