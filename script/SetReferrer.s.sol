// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script, console2 } from "forge-std/Script.sol";
import { AxiomReferralMockHelper } from "../src/AxiomReferralMockHelper.sol";

contract SetReferrer is Script {
    function setUp() public { }

    function run() public {
        AxiomReferralMockHelper a = AxiomReferralMockHelper(0x9698a5f9e16CA04FBcF61468d3FdBfF515741D76);
        vm.startBroadcast();
        a.setReferrer(address(0xdeadbeef), address(0xefefefef));
        vm.stopBroadcast();
    }
}
