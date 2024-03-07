// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {Test} from 'forge-std/Test.sol';
import {XERC20} from '../../contracts/XERC20.sol';
import {XERC20Factory} from '../../contracts/XERC20Factory.sol';
import {OmniNetworkEscrow} from '../../contracts/OmniNetworkEscrow.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

abstract contract Base is Test {
  address internal _owner = vm.addr(1);
  address internal _user = vm.addr(2);
  address internal _minter = vm.addr(3);

  XERC20Factory internal _xerc20Factory = new XERC20Factory();

  XERC20 internal _xerc20;
  OmniNetworkEscrow internal _escrow;

  struct XERC20Listing {
    uint256 claimDeadline;
    uint256 totalClaimable;
    address nftGated;
    uint256 totalClaimedWallets;
  }

  event BridgeLimitsSet(uint256 _mintingLimit, uint256 _burningLimit, address indexed _bridge);
  event LockboxSet(address _lockbox);
  event SetLimitsDelay(uint256 _delay);

  event TokenCollected(address indexed token, address indexed walletAddress, uint256 timestamp);

  function setUp() public virtual {
    vm.startPrank(_owner);
    uint256[] memory limits = new uint256[](1);
    limits[0] = type(uint256).max;

    address[] memory bridges = new address[](1);
    bridges[0] = address(_escrow);

    _xerc20 = XERC20(_xerc20Factory.deployXERC20('Test', 'TST', limits, limits, bridges));
    _escrow = new OmniNetworkEscrow(_owner);
    _xerc20.setLimits(address(_escrow), 100, 100);
    vm.stopPrank();
  }
}

contract UnitListing is Base {
  function testListingRevertIfNotOwner() public {
    vm.expectRevert(OmniNetworkEscrow.AccessControl_CallerNotOwner.selector);
    _escrow.listXERC20Token(address(_xerc20), block.timestamp + 100, 1, address(0), '');
  }

  function testListingRevertIfAlreadyListed() public {
    vm.startPrank(_owner);
    _escrow.listXERC20Token(address(_xerc20), block.timestamp + 100, 1, address(0), '');

    vm.expectRevert(OmniNetworkEscrow.OmniEscrow_AlreadyListed.selector);
    _escrow.listXERC20Token(address(_xerc20), block.timestamp + 100, 1, address(0), '');
    vm.stopPrank();
  }

  function testListingRevertIfTimestampIsNotInTheFuture() public {
    vm.startPrank(_owner);
    vm.expectRevert(OmniNetworkEscrow.OmniEscrow_DeadlineMustBeInTheFuture.selector);
    _escrow.listXERC20Token(address(_xerc20), block.timestamp, 1, address(0), '');
    vm.stopPrank();
  }

  function testListingRevertIfAmountToClaimIsZero() public {
    vm.startPrank(_owner);
    vm.expectRevert(OmniNetworkEscrow.OmniEscrow_TotalClaimableBiggerThanZero.selector);
    _escrow.listXERC20Token(address(_xerc20), block.timestamp + 1, 0, address(0), '');
    vm.stopPrank();
  }

  function testListing() public {
    vm.startPrank(_owner);
    _escrow.listXERC20Token(address(_xerc20), block.timestamp + 100, 1, address(0), '');
    vm.stopPrank();

    (, uint256 claimDeadline, uint256 totalClaimable, address nftGated, uint256 totalClaimedWallets,) =
      _escrow.listedTokenDetails(address(_xerc20));

    assertEq(claimDeadline, block.timestamp + 100);
    assertEq(totalClaimable, 1);
    assertEq(nftGated, address(0));
    assertEq(totalClaimedWallets, 0);

    assertEq(_escrow.getXERC20TokenCount(), 1);
  }
}

contract CollectUnitTest is Base {
  function testCollectRevertIfAlreadyClaimed() public {
    vm.startPrank(_owner);

    _escrow.listXERC20Token(address(_xerc20), block.timestamp + 100, 1, address(0), '');

    vm.stopPrank();

    // First claim
    vm.startPrank(_user);
    _escrow.collectXERC20(address(_xerc20));
    vm.stopPrank();

    vm.startPrank(_user);
    vm.expectRevert(OmniNetworkEscrow.OmniEscrow_AlreadyClaimed.selector);
    _escrow.collectXERC20(address(_xerc20));
    vm.stopPrank();
  }

  function testCollectRevertExpiredWindowClaim() public {
    vm.startPrank(_owner);

    _escrow.listXERC20Token(address(_xerc20), block.timestamp + 100, 1, address(0), '');

    vm.stopPrank();

    // Move after deadline
    vm.warp(block.timestamp + 101);

    vm.startPrank(_user);
    vm.expectRevert(OmniNetworkEscrow.OmniEscrow_DeadlineMustBeInTheFuture.selector);
    _escrow.collectXERC20(address(_xerc20));
    vm.stopPrank();
  }

  // TODO: Implement ERC721Mock
  // function testCollectRevertIfNotOwnsNFT() public {
  // }

  function testCollectSuccess() public {
    uint256 balanceTokenBefore = IERC20(_xerc20).balanceOf(_user);

    vm.startPrank(_owner);

    _escrow.listXERC20Token(address(_xerc20), block.timestamp + 100, 1, address(0), '');

    vm.stopPrank();

    // Already listed, check the listing
    (,, uint256 totalClaimable,, uint256 totalClaimedWallets,) = _escrow.listedTokenDetails(address(_xerc20));

    // First claim
    vm.startPrank(_user);
    vm.expectEmit(true, true, true, false);

    emit TokenCollected(address(_xerc20), _user, block.timestamp);
    _escrow.collectXERC20(address(_xerc20));

    (,,,, uint256 totalClaimedWalletsAfter,) = _escrow.listedTokenDetails(address(_xerc20));

    uint256 timestampClaim = _escrow.claimedWallets(address(_xerc20), _user);

    assertGt(timestampClaim, 0);
    assertEq(totalClaimedWallets + 1, totalClaimedWalletsAfter);

    assertEq(IERC20(_xerc20).balanceOf(_user), balanceTokenBefore + totalClaimable);

    vm.stopPrank();
  }
}
