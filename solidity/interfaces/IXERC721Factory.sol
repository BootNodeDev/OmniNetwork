// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

interface IXERC721Factory {
  /**
   * @notice Emitted when a new XERC721 is deployed
   *
   * @param _xerc721 The address of the xerc721
   */
  event XERC721Deployed(address _xerc721);

  //   /**
  //    * @notice Emitted when a new XERC721Lockbox is deployed
  //    *
  //    * @param _lockbox The address of the lockbox
  //    */
  //   event LockboxDeployed(address _lockbox);

  /**
   * @notice Reverts when a non-owner attempts to call
   */
  error IXERC721Factory_NotOwner();

  //   /**
  //    * @notice Reverts when a lockbox is trying to be deployed from a malicious address
  //    */
  //   error IXERC721Factory_BadTokenAddress();

  //   /**
  //    * @notice Reverts when a lockbox is already deployed
  //    */
  //   error IXERC721Factory_LockboxAlreadyDeployed();

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

  //   /**
  //    * @notice Deploys an XERC721Lockbox contract using CREATE3
  //    *
  //    * @param _xerc721 The address of the xerc721 that you want to deploy a lockbox for
  //    * @param _baseToken The address of the base token that you want to lock
  //    * @param _isNative Whether or not the base token is native
  //    * @return _lockbox The address of the lockbox
  //    */
  //   function deployLockbox(
  //     address _xerc721,
  //     address _baseToken,
  //     bool _isNative
  //   ) external returns (address payable _lockbox);
}
