// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

// solhint-disable-next-line no-console
import {console} from "forge-std/console.sol";
import {OmniNetworkEscrow} from "../contracts/OmniNetworkEscrow.sol";
import {Script} from "forge-std/Script.sol";
import {ScriptingLibrary} from "./ScriptingLibrary/ScriptingLibrary.sol";

contract OmniNetworkEscrowDeploy is Script, ScriptingLibrary {
    function run() public {
        OmniNetworkEscrow _escrow = new OmniNetworkEscrow();

        // solhint-disable-next-line no-console
        console.log("OmniNetworkEscrow deployed to:", address(_escrow));
    }
}
