// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

interface IXERC721Factory {
  /**
   * @notice Emitted when a new XERC721 is deployed
   *
   * @param _xerc721 The address of the xerc721
   */
  event XERC721Deployed(address _xerc721);

  /**
   * @notice Reverts when a non-owner attempts to call
   */
  error IXERC721Factory_NotOwner();

  /**
   * @notice Reverts when a the length of arrays sent is incorrect
   */
  error IXERC721Factory_InvalidLength();

  /**
   * @notice Deploys an XERC721 contract using CREATE3
   * @dev _limits and _minters must be the same length
   * @param _name The name of the token
   * @param _symbol The symbol of the token
   * @param _minterLimits The array of minter limits that you are adding (optional, can be an empty array)
   * @param _burnerLimits The array of burning limits that you are adding (optional, can be an empty array)
   * @param _bridges The array of burners that you are adding (optional, can be an empty array)
   * @return _xerc721 The address of the xerc721
   */
  function deployXERC721(
    string memory _name,
    string memory _symbol,
    uint256[] memory _minterLimits,
    uint256[] memory _burnerLimits,
    address[] memory _bridges
  ) external returns (address _xerc721);
}
