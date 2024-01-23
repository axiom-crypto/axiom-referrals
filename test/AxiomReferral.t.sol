// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { AxiomTest } from "@axiom-crypto/v2-periphery/test/AxiomTest.sol";
import { AxiomVm } from "@axiom-crypto/v2-periphery/test/AxiomVm.sol";

import { AxiomReferral } from "../src/AxiomReferral.sol";

contract AxiomReferralTest is AxiomTest {
    AxiomReferral public axiomReferral;

    event Claim(address indexed referrer, uint256 startClaimId, uint256 endClaimId, uint256 totalTradeVolume);

    function setUp() public {
        _createSelectForkAndSetupAxiom("sepolia", 5_141_172);

        inputPath = "app/axiom/data/inputs.json";
        querySchema = axiomVm.compile("app/axiom/main.circuit.ts", inputPath);
        axiomReferral = new AxiomReferral(axiomV2QueryAddress, uint64(block.chainid), querySchema);
    }

    function test_axiomSendQuery() public {
        AxiomVm.AxiomSendQueryArgs memory args =
            axiomVm.sendQueryArgs(inputPath, address(axiomReferral), callbackExtraData, feeData);

        axiomV2Query.sendQuery{ value: args.value }(
            args.sourceChainId,
            args.dataQueryHash,
            args.computeQuery,
            args.callback,
            args.feeData,
            args.userSalt,
            args.refundee,
            args.dataQuery
        );
    }

    function test_AxiomCallback() public {
        AxiomVm.AxiomFulfillCallbackArgs memory args =
            axiomVm.fulfillCallbackArgs(inputPath, address(axiomReferral), callbackExtraData, feeData, msg.sender);
        vm.expectEmit();
        emit Claim(
            address(uint160(uint256(args.axiomResults[2]))),
            uint256(args.axiomResults[0]),
            uint256(args.axiomResults[1]),
            uint256(args.axiomResults[3])
        );
        axiomVm.prankCallback(args);
        require(
            axiomReferral.lastClaimedId(address(uint160(uint256(args.axiomResults[2]))))
                == uint256(args.axiomResults[1]),
            "Last claim ID not updated"
        );
    }
}
