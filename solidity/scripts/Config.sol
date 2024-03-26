// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

// NOTE: IMPORTANT! Struct members should be order by ALPHABETICAL order. DO NOT modify them.
// Please read https://book.getfoundry.sh/cheatcodes/parse-json to understand the
// limitations and caveats of the JSON parsing cheats.
struct ERC20Config {
  address erc20; // The address of the ERC20 canonical token of that chain (address(0) if none)
  address factory; // The factory to use for deploy
  bool isNativeGasToken; // Whether or not the token is the native gas token of the chain. E.g. Are you deploying an xERC20 for MATIC in Polygon?
  string name; // The name to use for the xERC20
  string symbol; // The symbol to use for the xERC20
}

struct ERC721Config {
  address factory; // The factory to use for deploy
  string name; // The name to use for the xERC20
  string symbol; // The symbol to use for the xERC20
}

struct DeployDetails {
  address bridge; // The address of the bridge
  uint256 burnLimit; // The 24hs burn limit of the bridge
  address governor; // The governor address of the xERC20
  uint256 mintLimit; // The 24hs mint limit of the bridge
  address relayerAddress;
  string rpcEnvName; // The name of the RPC to use from the .env file
  ERC20Config testERC20;
  ERC721Config testERC721;
}

////////////////////////// MODIFY ////////////////////////////////
// When new factories need to be deployed, make sure to update the salt version to avoid address collition
string constant SALT = 'omni-v1.0';
//////////////////////////////////////////////////////////////////
