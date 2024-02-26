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

// NOTE: IMPORTANT! Struct members should be order by ALPHABETICAL order. DO NOT modify them.
// Please read https://book.getfoundry.sh/cheatcodes/parse-json to understand the
// limitations and caveats of the JSON parsing cheats.
struct BridgeDetails {
  address bridge; // The address of the bridge
  uint256 burnLimit; // The 24hs burn limit of the bridge
  uint256 mintLimit; // The 24hs mint limit of the bridge
}

struct ChainDetails {
  BridgeDetails[] bridgeDetails; // The array of bridges to configure for this chain
  address erc721; // The address of the ERC721 canonical token of that chain (address(0) if none)
  address governor; // The governor address of the xERC721
  bool isNativeGasToken; // Whether or not the token is the native gas token of the chain. E.g. Are you deploying an xERC721 for MATIC in Polygon?
  string rpcEnvName; // The name of the RPC to use from the .env file
}

struct DeploymentConfig {
  ChainDetails[] chainDetails;
  string name; // The name to use for the xERC721
  string symbol; // The symbol to use for the xERC721
}

contract XERC721Deploy is Script, ScriptingLibrary {
  using stdJson for string;

  uint256 public deployer = vm.envUint('DEPLOYER_PRIVATE_KEY');
  address public factoryAddress = vm.envAddress('XERC721_FACTORY');
  XERC721Factory public factory = XERC721Factory(factoryAddress);

  function run() public {
    string memory _json = vm.readFile('./solidity/scripts/xerc721-deployment-config.json');
    DeploymentConfig memory _data = abi.decode(_json.parseRaw('.'), (DeploymentConfig));
    uint256 _chainAmount = _data.chainDetails.length;
    address[] memory _tokens = new address[](_chainAmount);

    for (uint256 i; i < _chainAmount; i++) {
      ChainDetails memory _chainDetails = _data.chainDetails[i];

      vm.createSelectFork(vm.rpcUrl(vm.envString(_chainDetails.rpcEnvName)));
      vm.startBroadcast(deployer);
      // If this chain does not have a factory we will revert
      require(
        keccak256(address(factory).code) != keccak256(address(0).code), 'There is no factory deployed on this chain'
      );

      BridgeDetails[] memory _bridgeDetails = _chainDetails.bridgeDetails;

      // flatten all bridge details
      address[] memory _bridges = new address[](_bridgeDetails.length);
      uint256[] memory _burnLimits = new uint256[](_bridgeDetails.length);
      uint256[] memory _mintLimits = new uint256[](_bridgeDetails.length);
      for (uint256 _bridgeIndex; _bridgeIndex < _bridgeDetails.length; _bridgeIndex++) {
        _bridges[_bridgeIndex] = _bridgeDetails[_bridgeIndex].bridge;
        _burnLimits[_bridgeIndex] = _bridgeDetails[_bridgeIndex].burnLimit;
        _mintLimits[_bridgeIndex] = _bridgeDetails[_bridgeIndex].mintLimit;
      }

      // deploy xerc721
      address _xerc721 = factory.deployXERC721(_data.name, _data.symbol, _mintLimits, _burnLimits, _bridges);

      // transfer xerc721 ownership to the governor
      XERC721(_xerc721).transferOwnership(_chainDetails.governor);

      vm.stopBroadcast();

      // solhint-disable-next-line no-console
      console.log('Deployment to chain with RPC name: ', _chainDetails.rpcEnvName);
      // solhint-disable-next-line no-console
      console.log('xERC721 token deployed: ', _xerc721);
      _tokens[i] = _xerc721;
    }

    if (_chainAmount > 1) {
      for (uint256 i = 1; i < _chainAmount; i++) {
        vm.assume(_tokens[i - 1] == _tokens[i]);
        vm.assume(keccak256(_tokens[i - 1].code) == keccak256(_tokens[i].code));
      }
    }
  }
}
