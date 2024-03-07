// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';
import {EnumerableMap} from '@openzeppelin/contracts/utils/structs/EnumerableMap.sol';

import {IXERC20} from '../interfaces/IXERC20.sol';
import {IXERC721} from '../interfaces/IXERC721.sol';

contract OmniNetworkEscrow is AccessControl {
  using EnumerableMap for EnumerableMap.UintToAddressMap;

  enum TokenType {
    XERC20,
    XERC721
  }

  bytes32 public constant OWNER_ROLE = keccak256('OWNER_ROLE');
  bytes32 public constant RELAYER_ROLE = keccak256('RELAYER_ROLE');

  error OmniEscrow_AlreadyListed();
  error OmniEscrow_NotListed();
  error OmniEscrow_DeadlineMustBeInTheFuture();
  error OmniEscrow_TotalClaimableBiggerThanZero();
  error OmniEscrow_AlreadyClaimed();
  error OmniEscrow_NFTGatedBalanceIsZero();
  error AccessControl_CallerNotOwner();
  error InvalidToken();

  struct Listing {
    TokenType tokenType;
    uint256 claimDeadline;
    uint256 totalClaimable;
    address nftGated;
    uint256 totalClaimedWallets;
    string imageUrl;
  }

  event TokenListed(
    address indexed _token, uint256 _claimDeadline, uint256 _totalClaimable, address _nftGated, string _imageUrl
  );
  event ResetCountdown(address indexed _token, uint256 _newClaimDeadline);
  event TokenCollected(address indexed _token, address indexed _walletAddress, uint256 _timestamp);

  bool private _useNftGated = false;

  // To iterate over the list of addresses and also distinguish between XERC20 and XERC721
  // we use two different maps, one for each type of token.
  // This way we can iterate over the list of addresses just traversing from index 0 to map.length()
  // as key, and each address as value.

  /**
   * @notice Map to store the addresses of listed xERC20 tokens
   * @dev The key represents the index, and the value is the token address
   */
  EnumerableMap.UintToAddressMap private _xerc20Addresses;

  /**
   * @notice Map to store the addresses of listed xERC721 tokens
   * @dev The key represents the index, and the value is the token address
   */
  EnumerableMap.UintToAddressMap private _xerc721Addresses;

  /**
   * @notice Map to store the details of listed xERC20 and xERC721 tokens
   * @dev The key represents the token address, and the value is the listing details
   */
  mapping(address token => Listing) public listedTokenDetails;

  /**
   * @notice For a pair of token/walletAddress, stores the timestamp of the last claim
   * @dev Every claim should happen only once. A timestamp 0 is considered as not claimed
   */
  mapping(address token => mapping(address walletAddress => uint256 timestamp)) public claimedWallets;

  modifier onlyOwner() {
    if (!hasRole(OWNER_ROLE, msg.sender)) {
      revert AccessControl_CallerNotOwner();
    }
    _;
  }

  modifier checkNftGating(address _token) {
    address _nftGate = listedTokenDetails[_token].nftGated;

    if (_nftGate != address(0) && _useNftGated) {
      if (ERC721(_nftGate).balanceOf(msg.sender) == 0) {
        revert OmniEscrow_NFTGatedBalanceIsZero();
      }
    }
    _;
  }

  constructor(address _relayer) {
    _grantRole(OWNER_ROLE, msg.sender);
    _grantRole(RELAYER_ROLE, _relayer);
  }

  function grantRelayerRole(address _relayer) public onlyOwner {
    _grantRole(RELAYER_ROLE, _relayer);
  }

  function _listToken(
    TokenType _tokenType,
    address _token,
    uint256 _claimDeadline,
    uint256 _totalClaimable,
    address _nftGated,
    string memory _imageUrl
  ) private {
    // check if already listed
    if (listedTokenDetails[_token].claimDeadline != uint256(0)) {
      revert OmniEscrow_AlreadyListed();
    }

    // check if deadline is in the future
    if (block.timestamp >= _claimDeadline) {
      revert OmniEscrow_DeadlineMustBeInTheFuture();
    }

    // check if total claimable is bigger than zero
    if (_totalClaimable == uint256(0)) {
      revert OmniEscrow_TotalClaimableBiggerThanZero();
    }

    listedTokenDetails[_token] = Listing({
      tokenType: _tokenType,
      claimDeadline: _claimDeadline,
      totalClaimable: _totalClaimable,
      nftGated: _nftGated,
      totalClaimedWallets: uint256(0),
      imageUrl: _imageUrl
    });
  }

  function _isXERC721Token(address _token) private view returns (bool _isXERC721) {
    (bool _tokenURI,) = address(_token).staticcall(abi.encodeWithSignature('tokenURI(uint256)'));
    (bool _ownerOf,) = address(_token).staticcall(abi.encodeWithSignature('ownerOf(uint256)'));
    //(bool _setLimits,) = address(_token).staticcall(abi.encodeWithSignature('setLimits(address,uint256,uint256)'));

    return _tokenURI && _ownerOf;
  }

  function _isXERC20Token(address _token) private view returns (bool _isXERC20) {
    (bool _decimals,) = address(_token).staticcall(abi.encodeWithSignature('decimals()'));
    // (bool _setLimits,) = address(_token).staticcall(abi.encodeWithSignature('setLimits(address,uint256,uint256)'));
    return _decimals;
  }

  /**
   * @notice Lists a XERC721 token
   * @dev Can only be called by the owner
   * @param _token The address of the XERC721 token
   * @param _claimDeadline The deadline for claiming the tokens
   * @param _nftGated The address of the NFT that is required to claim the tokens (can be zeroAddress if no NFT is required)
   * @param _imageUrl The url of the logo
   */
  function listXERC721Token(
    address _token,
    uint256 _claimDeadline,
    address _nftGated,
    string memory _imageUrl
  ) public onlyOwner {
    if (!_isXERC721Token(_token)) {
      revert InvalidToken();
    }

    _listToken(TokenType.XERC721, _token, _claimDeadline, 1, _nftGated, _imageUrl);

    _xerc721Addresses.set(_xerc721Addresses.length(), _token);

    emit TokenListed(_token, _claimDeadline, 1, _nftGated, _imageUrl);
  }

  /**
   * @notice Lists a XERC20 token
   * @dev Can only be called by the owner
   * @param _token The address of the XERC20 token
   * @param _claimDeadline The deadline for claiming the tokens
   * @param _totalClaimable The total amount of tokens that can be claimed
   * @param _nftGated The address of the NFT that is required to claim the tokens (can be zeroAddress if no NFT is required)
   * @param _imageUrl The url of the logo
   */
  function listXERC20Token(
    address _token,
    uint256 _claimDeadline,
    uint256 _totalClaimable,
    address _nftGated,
    string memory _imageUrl
  ) public onlyOwner {
    if (!_isXERC20Token(_token)) {
      revert InvalidToken();
    }

    _listToken(TokenType.XERC20, _token, _claimDeadline, _totalClaimable, _nftGated, _imageUrl);

    _xerc20Addresses.set(_xerc20Addresses.length(), _token);

    emit TokenListed(_token, _claimDeadline, _totalClaimable, _nftGated, _imageUrl);
  }

  /**
   * @notice Reset countdown for a token
   * @dev Can only be called by the owner
   * @param _token The address of the  token
   * @param _newClaimDeadline The deadline for claiming the tokens
   */
  function resetCountdownOfListedToken(address _token, uint256 _newClaimDeadline) public onlyOwner {
    // check if is listed
    if (listedTokenDetails[_token].claimDeadline == uint256(0)) {
      revert OmniEscrow_NotListed();
    }

    // check if deadline is in the future
    if (block.timestamp >= _newClaimDeadline) {
      revert OmniEscrow_DeadlineMustBeInTheFuture();
    }

    listedTokenDetails[_token].claimDeadline = _newClaimDeadline;

    emit ResetCountdown(_token, _newClaimDeadline);
  }

  /**
   * @dev Collects the specified token from the contract and transfers it to the caller.
   * @param _token The address of the token to be collected.
   */
  function collectXERC20(address _token) public checkNftGating(_token) {
    // check if the caller has already claimed the tokens
    if (claimedWallets[_token][msg.sender] != uint256(0)) {
      revert OmniEscrow_AlreadyClaimed();
    }

    // check if the deadline has passed
    if (block.timestamp > listedTokenDetails[_token].claimDeadline) {
      revert OmniEscrow_DeadlineMustBeInTheFuture();
    }

    listedTokenDetails[_token].totalClaimedWallets += 1;
    claimedWallets[_token][msg.sender] = block.timestamp;

    IXERC20(_token).mint(msg.sender, listedTokenDetails[_token].totalClaimable);

    emit TokenCollected(_token, msg.sender, block.timestamp);
  }

  /**
   * @dev Collects the specified token from the contract and transfers it to the caller.
   * @param _token The address of the token to be collected.
   */
  function collectXERC721(address _token) public checkNftGating(_token) {
    // check if the caller has already claimed the tokens
    if (claimedWallets[_token][msg.sender] != uint256(0)) {
      revert OmniEscrow_AlreadyClaimed();
    }

    // check if the deadline has passed
    if (block.timestamp > listedTokenDetails[_token].claimDeadline) {
      revert OmniEscrow_DeadlineMustBeInTheFuture();
    }

    IXERC721(_token).mint(msg.sender, '');

    listedTokenDetails[_token].totalClaimedWallets += 1;
    claimedWallets[_token][msg.sender] = block.timestamp;

    emit TokenCollected(_token, msg.sender, block.timestamp);
  }

  /**
   * @notice Returns the number of listed xERC20 tokens
   * @return _xerc20Count The number of listed xERC20 tokens
   */
  function getXERC20TokenCount() public view returns (uint256 _xerc20Count) {
    return _xerc20Addresses.length();
  }

  /**
   * @notice Returns the number of listed xERC721 tokens
   * @return _xerc721Count The number of listed xERC721 tokens
   */
  function getXERC721TokenCount() public view returns (uint256 _xerc721Count) {
    return _xerc721Addresses.length();
  }

  /**
   * @notice Returns the address of the token at the specified index
   * @param _index The index of the token
   * @return _xerc20AtIndex The address of the token
   */
  function getXERC20TokenAtIndex(uint256 _index) public view returns (address _xerc20AtIndex) {
    return _xerc20Addresses.get(_index);
  }

  /**
   * @notice Returns the address of the token at the specified index
   * @param _index The index of the token
   * @return _xerc721AtIndex The address of the token
   */
  function getXERC721TokenAtIndex(uint256 _index) public view returns (address _xerc721AtIndex) {
    return _xerc721Addresses.get(_index);
  }

  /**
   * @notice Set useNftGated onchain
   * @param _nftGated Whether to use NFT gating.
   */
  function setUseNftGated(bool _nftGated) public onlyOwner {
    _useNftGated = _nftGated;
  }
}
