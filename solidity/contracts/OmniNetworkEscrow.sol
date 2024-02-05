// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '../interfaces/IXERC20.sol';

// TODO make it upgradeable
contract OmniNetworkEscrow is Ownable {
  error OmniEscrow_AlreadyListed();
  error OmniEscrow_DeadlineMustBeInTheFuture();
  error OmniEscrow_TotalClaimableBiggerThanZero();
  error OmniEscrow_AlreadyClaimed();

  struct XERC20Listing {
    IXERC20 token;
    uint256 claimDeadline;
    uint256 totalClaimable;
    address nftGated;
  }

  mapping(address => XERC20Listing) listings;
  // token => address => timestamp
  mapping(address => mapping(address => uint256)) claimedWallets;

  /**
   * @notice Lists a XERC20 token
   * @dev Can only be called by the owner
   * @param _token The address of the XERC20 token
   * @param _claimDeadline The deadline for claiming the tokens
   * @param _totalClaimable The total amount of tokens that can be claimed
   * @param _nftGated The address of the NFT that is required to claim the tokens (can be zeroAddress if no NFT is required)
   */
  function listXERC20Token(
    address _token,
    uint256 _claimDeadline,
    uint256 _totalClaimable,
    address _nftGated
  ) public onlyOwner {
    // check if already listed
    if (listings[_token].token != IXERC20(address(0))) {
      revert OmniEscrow_AlreadyListed();
    }

    // check if deadline is in the future
    if (block.timestamp > _claimDeadline) {
      revert OmniEscrow_DeadlineMustBeInTheFuture();
    }

    // check if total claimable is bigger than zero
    if (_totalClaimable == uint256(0)) {
      revert OmniEscrow_TotalClaimableBiggerThanZero();
    }

    listings[_token] = XERC20Listing({
      token: IXERC20(_token),
      claimDeadline: _claimDeadline,
      totalClaimable: _totalClaimable,
      nftGated: _nftGated
    });

    // TODO emit event
  }

  /**
   * @dev Collects the specified token from the contract and transfers it to the caller.
   * @param _token The address of the token to be collected.
   */
  function collect(address _token) public {
    // check if the caller has already claimed the tokens
    if (claimedWallets[_token][msg.sender] != uint256(0)) {
      revert OmniEscrow_AlreadyClaimed();
    }

    // check if the deadline has passed
    if (block.timestamp > listings[_token].claimDeadline) {
      revert OmniEscrow_DeadlineMustBeInTheFuture();
    }

    // check if the caller has the required NFT
    if (listings[_token].nftGated != address(0)) {
      require(
        ERC721(listings[_token].nftGated).balanceOf(msg.sender) > 0, 'OmniEscrow: caller does not have the required NFT'
      );
    }

    claimedWallets[_token][msg.sender] = block.timestamp;
    ERC20(_token).transfer(msg.sender, listings[_token].totalClaimable);

    // TODO emit event
  }
}
