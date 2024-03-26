// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

// solhint-disable-next-line no-console
import {console} from 'forge-std/console.sol';
import {OmniNetworkEscrow} from '../contracts/OmniNetworkEscrow.sol';
import {Script} from 'forge-std/Script.sol';
import {stdJson} from 'forge-std/StdJson.sol';
import {ScriptingLibrary} from './ScriptingLibrary/ScriptingLibrary.sol';
import {DeployDetails} from './Config.sol';

contract OmniNetworkEscrowDeploy is Script, ScriptingLibrary {
  using stdJson for string;

  uint256 public deployer = vm.envUint('DEPLOYER_PRIVATE_KEY');

  function run() public {
    string memory _json = vm.readFile('./solidity/scripts/config.json');
    DeployDetails memory _config = abi.decode(_json.parseRaw('.'), (DeployDetails));

    vm.createSelectFork(vm.rpcUrl(vm.envString(_config.rpcEnvName)));

    vm.startBroadcast(deployer);
    OmniNetworkEscrow _escrow = new OmniNetworkEscrow(_config.relayerAddress, _config.governor);
    vm.stopBroadcast();

    // solhint-disable-next-line no-console
    console.log('OmniNetworkEscrow deployed to:', address(_escrow));
  }
}
