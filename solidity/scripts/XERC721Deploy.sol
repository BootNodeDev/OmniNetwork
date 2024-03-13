// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

// solhint-disable-next-line no-console
import {console} from 'forge-std/console.sol';
import {Test} from 'forge-std/Test.sol';
import {Script} from 'forge-std/Script.sol';
import {stdJson} from 'forge-std/StdJson.sol';
import {XERC721} from '../contracts/XERC721.sol';
import {XERC721Factory, IXERC721Factory} from '../contracts/XERC721Factory.sol';
import {ScriptingLibrary} from './ScriptingLibrary/ScriptingLibrary.sol';
import {DeployDetails, SALT} from './Config.sol';

contract XERC721Deploy is Script, ScriptingLibrary {
  using stdJson for string;

  uint256 public deployer = vm.envUint('DEPLOYER_PRIVATE_KEY');

  function run() public {
    string memory _json = vm.readFile('./solidity/scripts/config.json');
    DeployDetails memory _config = abi.decode(_json.parseRaw('.'), (DeployDetails));
    XERC721Factory factory = XERC721Factory(_config.testERC721.factory);

    vm.createSelectFork(vm.rpcUrl(vm.envString(_config.rpcEnvName)));
    vm.startBroadcast(deployer);

    // If this chain does not have a factory we will revert
    require(
      keccak256(address(factory).code) != keccak256(address(0).code), 'There is no factory deployed on this chain'
    );

    // flatten all bridge details
    address[] memory _bridges = new address[](1);
    uint256[] memory _burnLimits = new uint256[](1);
    uint256[] memory _mintLimits = new uint256[](1);
    _bridges[0] = _config.bridge;
    _burnLimits[0] = _config.burnLimit;
    _mintLimits[0] = _config.mintLimit;

    // deploy xerc721
    address _xerc721 =
      factory.deployXERC721(_config.testERC721.name, _config.testERC721.symbol, _mintLimits, _burnLimits, _bridges);

    // transfer xerc721 ownership to the governor
    XERC721(_xerc721).transferOwnership(_config.governor);

    vm.stopBroadcast();

    // solhint-disable-next-line no-console
    console.log('Deployment to chain with RPC name: ', _config.rpcEnvName);
    // solhint-disable-next-line no-console
    console.log('xERC721 token deployed: ', _xerc721);
  }
}
