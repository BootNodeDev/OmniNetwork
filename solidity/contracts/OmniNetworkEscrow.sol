// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "../interfaces/IXERC20.sol";

// TODO make it upgradeable
contract OmniNetworkEscrow is Ownable {
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    error OmniEscrow_AlreadyListed();
    error OmniEscrow_DeadlineMustBeInTheFuture();
    error OmniEscrow_TotalClaimableBiggerThanZero();
    error OmniEscrow_AlreadyClaimed();
    error OmniEscrow_NFTGatedBalanceIsZero();

    struct XERC20Listing {
        uint256 claimDeadline;
        uint256 totalClaimable;
        address nftGated;
        uint256 totalClaimedWallets;
    }

    event TokenListed(address indexed token);
    event TokenCollected(address indexed token, address indexed walletAddress);

    EnumerableMap.UintToAddressMap private listedTokens;
    mapping(address token => XERC20Listing) public listings;

    mapping(address token => mapping(address walletAddress => uint256 timestamp))
        public claimedWallets;

    /**
     * @notice Lists a token
     * @dev Can only be called by the owner
     * @param _token The address of the XERC20 token
     * @param _claimDeadline The deadline for claiming the tokens
     * @param _totalClaimable The total amount of tokens that can be claimed
     * @param _nftGated The address of the NFT that is required to claim the tokens (can be zeroAddress if no NFT is required)
     */
    function listToken(
        address _token,
        uint256 _claimDeadline,
        uint256 _totalClaimable,
        address _nftGated
    ) public onlyOwner {
        // check if already listed
        if (listings[_token].totalClaimable != uint256(0)) {
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

        // create listing
        listings[_token] = XERC20Listing({
            claimDeadline: _claimDeadline,
            totalClaimable: _totalClaimable,
            nftGated: _nftGated,
            totalClaimedWallets: uint256(0)
        });

        // set token as listed
        listedTokens.set(listedTokens.length(), _token);

        emit TokenListed(_token);
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
            if (ERC721(listings[_token].nftGated).balanceOf(msg.sender) > 0) {
                revert OmniEscrow_NFTGatedBalanceIsZero();
            }
        }

        listings[_token].totalClaimedWallets += 1;
        claimedWallets[_token][msg.sender] = block.timestamp;
        IXERC20(_token).mint(msg.sender, listings[_token].totalClaimable);

        emit TokenCollected(_token, msg.sender);
    }

    /**
     * @notice Returns the address of the token at the specified index
     * @param _index The index of the token
     * @return The address of the token
     */
    function getTokenAtIndex(uint256 _index) public view returns (address) {
        return listedTokens.get(_index);
    }

    /**
     * @notice Returns the number of listed tokens
     * @return The number of listed tokens
     */
    function getListingCount() public view returns (uint256) {
        return listedTokens.length();
    }
}
