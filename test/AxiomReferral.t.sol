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
        address referrer;
        uint64 numClaims;
    }

    AxiomInput public input;
    bytes32 public querySchema;

    event Claim(address indexed referrer, uint256 startClaimId, uint256 endClaimId, uint256 totalTradeVolume);

    function setUp() public {
        _createSelectForkAndSetupAxiom("sepolia", 5_141_172);

        uint64[] memory blockNumbers = new uint64[](2);
        blockNumbers[0] = 5_141_171;
        blockNumbers[1] = 5_141_525;
        uint64[] memory txIdxs = new uint64[](2);
        txIdxs[0] = 62;
        txIdxs[1] = 62;
        uint64[] memory logIdxs = new uint64[](2);
        logIdxs[0] = 0;
        logIdxs[1] = 0;
        input = AxiomInput({
            blockNumbers: blockNumbers,
            txIdxs: txIdxs,
            logIdxs: logIdxs,
            referrer: 0x00000000000000000000000000000000EFefeFEF,
            numClaims: 2
        });
        querySchema = axiomVm.readCircuit("app/axiom/main.circuit.ts");
        axiomReferral = new AxiomReferral(axiomV2QueryAddress, uint64(block.chainid), querySchema);
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
            axiomReferral.lastClaimedId(address(uint160(uint256(results[2])))) == uint256(results[1]),
            "Last claim ID not updated"
        );
    }
}
