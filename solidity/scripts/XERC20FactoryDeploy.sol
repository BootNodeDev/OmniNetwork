// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

// solhint-disable-next-line no-console
import {console} from 'forge-std/console.sol';
import {XERC20Factory, IXERC20Factory} from '../contracts/XERC20Factory.sol';
import {Script} from 'forge-std/Script.sol';
import {stdJson} from 'forge-std/StdJson.sol';
import {ScriptingLibrary} from './ScriptingLibrary/ScriptingLibrary.sol';
import {DeployDetails, SALT} from './Config.sol';

contract XERC20FactoryDeploy is Script, ScriptingLibrary {
  using stdJson for string;

  uint256 public deployerPk = vm.envUint('DEPLOYER_PRIVATE_KEY');

  function run() public {
    string memory _json = vm.readFile('./solidity/scripts/config.json');
    DeployDetails memory _config = abi.decode(_json.parseRaw('.'), (DeployDetails));

    vm.createSelectFork(vm.rpcUrl(vm.envString(_config.rpcEnvName)));

    bytes32 _salt = keccak256(abi.encodePacked(SALT, msg.sender));

    vm.startBroadcast(deployerPk);

    XERC20Factory _factory = new XERC20Factory{salt: _salt}();
    vm.stopBroadcast();

    // solhint-disable-next-line no-console
    console.log('Factory XERC20 deployed to:', address(_factory));
  }
}
