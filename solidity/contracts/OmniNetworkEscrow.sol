// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import '@openzeppelin/contracts/utils/structs/EnumerableMap.sol';
import '../interfaces/IXERC20.sol';
import '../interfaces/IXERC721.sol';

contract OmniNetworkEscrow is Ownable {
  using EnumerableMap for EnumerableMap.UintToAddressMap;
  using Counters for Counters.Counter;

  error OmniEscrow_AlreadyListed();
  error OmniEscrow_NotListed();
  error OmniEscrow_DeadlineMustBeInTheFuture();
  error OmniEscrow_TotalClaimableBiggerThanZero();
  error OmniEscrow_AlreadyClaimed();
  error OmniEscrow_NFTGatedBalanceIsZero();

  struct XERC20Listing {
    uint256 claimDeadline;
    uint256 totalClaimable;
    address nftGated;
    uint256 totalClaimedWallets;
    string imageUrl;
  }

  struct XERC721Listing {
    uint256 claimDeadline;
    address nftGated;
    uint256 totalClaimedWallets;
    Counters.Counter tokenId;
    string imageUrl;
  }

  event TokenListed(
    address indexed token, uint256 claimDeadline, uint256 totalClaimable, address nftGated, string imageUrl
  );
  event ResetCountdown(address indexed token, uint256 newClaimDeadline);
  event TokenCollected(address indexed token, address indexed walletAddress, uint256 timestamp);

  bool private useNftGated = false;

  EnumerableMap.UintToAddressMap private listedXERC20Tokens;
  EnumerableMap.UintToAddressMap private listedXERC721Tokens;

  mapping(address token => XERC20Listing) public listingsXERC20;
  mapping(address token => XERC721Listing) public listingsXERC721;

  mapping(address token => mapping(address walletAddress => uint256 timestamp)) public claimedWallets;

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
    // check if already listed
    if (listingsXERC20[_token].totalClaimable != uint256(0)) {
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

    // create listing
    listingsXERC20[_token] = XERC20Listing({
      claimDeadline: _claimDeadline,
      totalClaimable: _totalClaimable,
      nftGated: _nftGated,
      totalClaimedWallets: uint256(0),
      imageUrl: _imageUrl
    });

    // set token as listed
    listedXERC20Tokens.set(listedXERC20Tokens.length(), _token);

    emit TokenListed(_token, _claimDeadline, _totalClaimable, _nftGated, _imageUrl);
  }

  /**
   * @notice Lists a XERC721 token
   * @dev Can only be called by the owner
   * @param _token The address of the XERC20 token
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
    // check if already listed
    if (listingsXERC721[_token].claimDeadline != uint256(0)) {
      revert OmniEscrow_AlreadyListed();
    }

    // check if deadline is in the future
    if (block.timestamp >= _claimDeadline) {
      revert OmniEscrow_DeadlineMustBeInTheFuture();
    }

    // create listing
    listingsXERC721[_token] = XERC721Listing({
      claimDeadline: _claimDeadline,
      tokenId: Counters.Counter(1),
      nftGated: _nftGated,
      totalClaimedWallets: uint256(0),
      imageUrl: _imageUrl
    });

    // set token as listed
    listedXERC20Tokens.set(listedXERC20Tokens.length(), _token);

    emit TokenListed(_token, _claimDeadline, 1, _nftGated, _imageUrl);
  }

  /**
   * @notice Reset countdown for a XERC20 token
   * @dev Can only be called by the owner
   * @param _token The address of the XERC20 token
   * @param _newClaimDeadline The deadline for claiming the tokens
   */
  function resetCountdownListedTokenXERC20(address _token, uint256 _newClaimDeadline) public onlyOwner {
    // check if is listed
    if (listingsXERC20[_token].claimDeadline == uint256(0)) {
      revert OmniEscrow_NotListed();
    }

    // check if deadline is in the future
    if (block.timestamp >= _newClaimDeadline) {
      revert OmniEscrow_DeadlineMustBeInTheFuture();
    }

    listingsXERC20[_token].claimDeadline = _newClaimDeadline;

    emit ResetCountdown(_token, _newClaimDeadline);
  }

  /**
   * @notice Reset countdown for a XERC721 token
   * @dev Can only be called by the owner
   * @param _token The address of the XERC721 token
   * @param _newClaimDeadline The deadline for claiming the tokens
   */
  function resetCountdownListedTokenXERC721(address _token, uint256 _newClaimDeadline) public onlyOwner {
    // check if is listed
    if (listingsXERC721[_token].claimDeadline == uint256(0)) {
      revert OmniEscrow_NotListed();
    }

    // check if deadline is in the future
    if (block.timestamp >= _newClaimDeadline) {
      revert OmniEscrow_DeadlineMustBeInTheFuture();
    }

    listingsXERC721[_token].claimDeadline = _newClaimDeadline;

    emit ResetCountdown(_token, _newClaimDeadline);
  }

  /**
   * @dev Collects the specified token from the contract and transfers it to the caller.
   * @param _token The address of the token to be collected.
   */
  function collectXERC20(address _token) public {
    // check if the caller has already claimed the tokens
    if (claimedWallets[_token][msg.sender] != uint256(0)) {
      revert OmniEscrow_AlreadyClaimed();
    }

    // check if the deadline has passed
    if (block.timestamp > listingsXERC20[_token].claimDeadline) {
      revert OmniEscrow_DeadlineMustBeInTheFuture();
    }

    // check if the caller has the required NFT
    if (listingsXERC20[_token].nftGated != address(0) && useNftGated) {
      if (ERC721(listingsXERC20[_token].nftGated).balanceOf(msg.sender) > 0) {
        revert OmniEscrow_NFTGatedBalanceIsZero();
      }
    }

    listingsXERC20[_token].totalClaimedWallets += 1;
    claimedWallets[_token][msg.sender] = block.timestamp;
    IXERC20(_token).mint(msg.sender, listingsXERC20[_token].totalClaimable);

    emit TokenCollected(_token, msg.sender, block.timestamp);
  }

  /**
   * @dev Collects the specified token from the contract and transfers it to the caller.
   * @param _token The address of the token to be collected.
   */
  function collectXERC721(address _token) public {
    // check if the caller has already claimed the tokens
    if (claimedWallets[_token][msg.sender] != uint256(0)) {
      revert OmniEscrow_AlreadyClaimed();
    }

    // check if the deadline has passed
    if (block.timestamp > listingsXERC721[_token].claimDeadline) {
      revert OmniEscrow_DeadlineMustBeInTheFuture();
    }

    // check if the caller has the required NFT
    if (listingsXERC721[_token].nftGated != address(0) && useNftGated) {
      if (ERC721(listingsXERC721[_token].nftGated).balanceOf(msg.sender) > 0) {
        revert OmniEscrow_NFTGatedBalanceIsZero();
      }
    }

    listingsXERC721[_token].totalClaimedWallets += 1;
    claimedWallets[_token][msg.sender] = block.timestamp;
    uint256 _id = listingsXERC721[_token].tokenId.current();
    IXERC721(_token).mint(msg.sender, _id, '');

    listingsXERC721[_token].tokenId.increment();

    emit TokenCollected(_token, msg.sender, block.timestamp);
  }

  /**
   * @notice Returns the address of the token at the specified index
   * @param _index The index of the token
   * @return The address of the token
   */
  function getXERC20TokenAtIndex(uint256 _index) public view returns (address) {
    return listedXERC20Tokens.get(_index);
  }

  /**
   * @notice Returns the number of listed tokens
   * @return The number of listed tokens
   */
  function getListingXERC20Count() public view returns (uint256) {
    return listedXERC20Tokens.length();
  }

  /**
   * @notice Returns the address of the token at the specified index
   * @param _index The index of the token
   * @return The address of the token
   */
  function getXERC721TokenAtIndex(uint256 _index) public view returns (address) {
    return listedXERC721Tokens.get(_index);
  }

  /**
   * @notice Returns the number of listed tokens
   * @return The number of listed tokens
   */
  function getListingXERC721Count() public view returns (uint256) {
    return listedXERC721Tokens.length();
  }

  /**
   * @notice Set useNftGated onchain
   * @param _useNftGated Whether to use NFT gating.
   */
  function setUseNftGated(bool _useNftGated) public onlyOwner {
    useNftGated = _useNftGated;
  }
}
