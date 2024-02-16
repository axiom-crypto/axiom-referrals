// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script, console2 } from "forge-std/Script.sol";
import { AxiomReferralMockHelper } from "../src/AxiomReferralMockHelper.sol";

contract Trade is Script {
    function setUp() public { }

    function run() public {
        AxiomReferralMockHelper a = AxiomReferralMockHelper(0x9698a5f9e16CA04FBcF61468d3FdBfF515741D76);
        vm.startBroadcast();
        a.emitTrade(address(0xdeadbeef), address(0x1), false, 1, 10_498_102, 0, 0, 0);
        vm.stopBroadcast();
    }
}
