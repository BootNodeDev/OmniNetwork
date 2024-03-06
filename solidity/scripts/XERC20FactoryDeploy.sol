// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

// solhint-disable-next-line no-console
import {console} from 'forge-std/console.sol';
import {XERC20Factory, IXERC20Factory} from '../contracts/XERC20Factory.sol';
import {Script} from 'forge-std/Script.sol';
import {stdJson} from 'forge-std/StdJson.sol';
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
  address erc721; // The address of the ERC20 canonical token of that chain (address(0) if none)
  address governor; // The governor address of the xERC20
  bool isNativeGasToken; // Whether or not the token is the native gas token of the chain. E.g. Are you deploying an xERC20 for MATIC in Polygon?
  string rpcEnvName; // The name of the RPC to use from the .env file
}

struct DeploymentConfig {
  ChainDetails[] chainDetails;
  string name; // The name to use for the xERC20
  string symbol; // The symbol to use for the xERC20
}

contract XERC20FactoryDeploy is Script, ScriptingLibrary {
  using stdJson for string;

  ////////////////////////// MODIFY ////////////////////////////////
  // When new factories need to be deployed, make sure to update the salt version to avoid address collition
  string public constant SALT = 'xERC20-v1.72';
  //////////////////////////////////////////////////////////////////

  uint256 public deployerPk = vm.envUint('DEPLOYER_PRIVATE_KEY');

  function run() public {
    string memory _json = vm.readFile('./solidity/scripts/xerc20-deployment-config.json');
    DeploymentConfig memory _data = abi.decode(_json.parseRaw('.'), (DeploymentConfig));
    uint256 _chainAmount = _data.chainDetails.length;

    for (uint256 i; i < _chainAmount; i++) {
      ChainDetails memory _chainDetails = _data.chainDetails[i];

      vm.createSelectFork(vm.rpcUrl(vm.envString(_chainDetails.rpcEnvName)));

      bytes32 _salt = keccak256(abi.encodePacked(SALT, msg.sender));

      vm.startBroadcast(deployerPk);

      XERC20Factory _factory = new XERC20Factory{salt: _salt}();
      vm.stopBroadcast();

      // solhint-disable-next-line no-console
      console.log('Factory XERC20 deployed to:', address(_factory));
    }
  }
}
