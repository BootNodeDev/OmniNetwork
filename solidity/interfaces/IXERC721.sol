// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

interface IXERC721 {
  /**
   * @notice Emits when a lockbox is set
   *
   * @param _lockbox The address of the lockbox
   */
  event LockboxSet(address _lockbox);

  /**
   * @notice Emits when a limit is set
   *
   * @param _mintingLimit The updated minting limit we are setting to the bridge
   * @param _burningLimit The updated burning limit we are setting to the bridge
   * @param _bridge The address of the bridge we are setting the limit too
   */
  event BridgeLimitsSet(uint256 _mintingLimit, uint256 _burningLimit, address indexed _bridge);

  /**
   * @notice Reverts when a user with too low of a limit tries to call mint/burn
   */
  error IXERC721_NotHighEnoughLimits();

  /**
   *
   * @notice Reverts when a bridge tries to burn a token without approval or ownership
   */
  error IXERC721_NotAllowedToBurn();

  struct Bridge {
    BridgeParameters minterParams;
    BridgeParameters burnerParams;
  }

  struct BridgeParameters {
    uint256 timestamp;
    uint256 ratePerSecond;
    uint256 maxLimit;
    uint256 currentLimit;
  }

  /**
   * @notice Sets the lockbox address
   *
   * @param _lockbox The address of the lockbox (0x0 if no lockbox)
   */
  function setLockbox(address _lockbox) external;

  /**
   * @notice Updates the limits of any bridge
   * @dev Can only be called by the owner
   * @param _mintingLimit The updated minting limit we are setting to the bridge
   * @param _burningLimit The updated burning limit we are setting to the bridge
   * @param _bridge The address of the bridge we are setting the limits too
   */
  function setLimits(address _bridge, uint256 _mintingLimit, uint256 _burningLimit) external;

  /**
   * @notice Returns the max limit of a bridge
   *
   * @param _bridge The bridge we are viewing the limits of
   * @return _limit The limit the bridge has
   */
  function mintingMaxLimitOf(address _bridge) external view returns (uint256 _limit);

  /**
   * @notice Returns the max limit of a bridge
   *
   * @param _bridge the bridge we are viewing the limits of
   * @return _limit The limit the bridge has
   */
  function burningMaxLimitOf(address _bridge) external view returns (uint256 _limit);

  /**
   * @notice Returns the current limit of a bridge
   *
   * @param _bridge The bridge we are viewing the limits of
   * @return _limit The limit the bridge has
   */
  function mintingCurrentLimitOf(address _bridge) external view returns (uint256 _limit);

  /**
   * @notice Returns the current limit of a bridge
   *
   * @param _bridge the bridge we are viewing the limits of
   * @return _limit The limit the bridge has
   */
  function burningCurrentLimitOf(address _bridge) external view returns (uint256 _limit);

  /**
   * @notice Mints a non-fungible token to a user
   * @dev Can only be called by a bridge
   * @param _user The address of the user to receive the minted non-fungible token
   * @param _tokenURI The metadata corresponding to the non-fungible token
   */
  function mint(address _user, string memory _tokenURI) external;

  /**
   * @notice Mints batch of non-fungible tokens to a user
   * @dev Can only be called by a bridge
   * @param _user The address of the user who needs tokens minted
   * @param _tokenURIList The list of metadata for each individual token
   */
  function mintBatch(address _user, string[] calldata _tokenURIList) external;

  /**
   * @notice Burns a non-fungible token for a user
   * @dev Can only be called by a bridge
   * @param _user The address of the user who needs to burn the non-fungible token
   * @param _tokenId The non-fungible token to burn
   */
  function burn(address _user, uint256 _tokenId) external;

  /**
   * @notice Burns non-fungible tokens for a user
   * @dev Can only be called by a bridge
   * @param _user The address of the user who needs tokens burned
   * @param _tokenIdList The list of non-fungible tokens to burn
   */
  function burnBatch(address _user, uint256[] calldata _tokenIdList) external;
}
