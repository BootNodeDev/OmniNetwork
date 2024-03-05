// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {console} from 'forge-std/console.sol';
import {OmniNetworkEscrow} from '../contracts/OmniNetworkEscrow.sol';
import {Script} from 'forge-std/Script.sol';
import {ScriptingLibrary} from './ScriptingLibrary/ScriptingLibrary.sol';

contract OmniNetworkEscrowDeploy is Script, ScriptingLibrary {
  uint256 public deployer = vm.envUint('DEPLOYER_PRIVATE_KEY');
  address public deployerAddress = vm.envAddress('DEPLOYER_ADDRESS');

  function run() public {
    vm.createSelectFork(vm.rpcUrl(vm.envString('ETHEREUM_SEPOLIA_RPC')));

    vm.startBroadcast(deployer);
    OmniNetworkEscrow _escrow = new OmniNetworkEscrow(deployerAddress);
    vm.stopBroadcast();

    // solhint-disable-next-line no-console
    console.log('OmniNetworkEscrow deployed to:', address(_escrow));
  }
}
