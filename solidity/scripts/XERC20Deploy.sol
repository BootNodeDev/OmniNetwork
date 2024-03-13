// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

// solhint-disable-next-line no-console
import {console} from 'forge-std/console.sol';
import {Test} from 'forge-std/Test.sol';
import {Script} from 'forge-std/Script.sol';
import {stdJson} from 'forge-std/StdJson.sol';
import {XERC20} from '../contracts/XERC20.sol';
import {XERC20Lockbox} from '../contracts/XERC20Lockbox.sol';
import {XERC20Factory, IXERC20Factory} from '../contracts/XERC20Factory.sol';
import {ScriptingLibrary} from './ScriptingLibrary/ScriptingLibrary.sol';
import {DeployDetails} from './Config.sol';

contract XERC20Deploy is Script, ScriptingLibrary {
  using stdJson for string;

  uint256 public deployer = vm.envUint('DEPLOYER_PRIVATE_KEY');

  function run() public {
    string memory _json = vm.readFile('./solidity/scripts/config.json');
    DeployDetails memory _config = abi.decode(_json.parseRaw('.'), (DeployDetails));

    vm.createSelectFork(vm.rpcUrl(vm.envString(_config.rpcEnvName)));
    XERC20Factory factory = XERC20Factory(_config.testERC20.factory);

    vm.startBroadcast(deployer);

    // If this chain does not have a factory we will revert
    require(
      keccak256(address(factory).code) != keccak256(address(0).code), 'There is no factory deployed on this chain'
    );

    address[] memory _bridges = new address[](1);
    uint256[] memory _burnLimits = new uint256[](1);
    uint256[] memory _mintLimits = new uint256[](1);
    _bridges[0] = _config.bridge;
    _burnLimits[0] = _config.burnLimit;
    _mintLimits[0] = _config.mintLimit;

    // deploy xerc20
    address _xerc20 =
      factory.deployXERC20(_config.testERC20.name, _config.testERC20.symbol, _mintLimits, _burnLimits, _bridges);

    // deploy lockbox if needed
    address _lockbox;
    if (_config.testERC20.erc20 != address(0) && !_config.testERC20.isNativeGasToken) {
      _lockbox = factory.deployLockbox(_xerc20, _config.testERC20.erc20, _config.testERC20.isNativeGasToken);
    }

    // transfer xerc20 ownership to the governor
    XERC20(_xerc20).transferOwnership(_config.governor);

    vm.stopBroadcast();

    // solhint-disable-next-line no-console
    console.log('Deployment to chain with RPC name: ', _config.rpcEnvName);
    // solhint-disable-next-line no-console
    console.log('xERC20 token deployed: ', _xerc20);
    if (_lockbox != address(0)) {
      // solhint-disable-next-line no-console
      console.log('Lockbox deployed: ', _lockbox);
    }
  }
}
