// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {Test} from 'forge-std/Test.sol';
import {XERC20} from '../../contracts/XERC20.sol';
import {OmniNetworkEscrow} from '../../contracts/OmniNetworkEscrow.sol';
import {IXERC20} from '../../interfaces/IXERC20.sol';

abstract contract Base is Test {
  address internal _owner = vm.addr(1);
  address internal _user = vm.addr(2);
  address internal _minter = vm.addr(3);

  XERC20 internal _xerc20;
  OmniNetworkEscrow internal _escrow;

  event BridgeLimitsSet(uint256 _mintingLimit, uint256 _burningLimit, address indexed _bridge);
  event LockboxSet(address _lockbox);
  event SetLimitsDelay(uint256 _delay);

  function setUp() public virtual {
    vm.startPrank(_owner);
    _xerc20 = new XERC20('Test', 'TST', _owner);
    _escrow = new OmniNetworkEscrow();
    _xerc20.setLimits(address(_escrow), 100, 100);
    vm.stopPrank();
  }
}

contract UnitListing is Base {
  function testListingRevertIfNotOwner() public {
    vm.expectRevert('Ownable: caller is not the owner');
    _escrow.listToken(address(_xerc20), block.timestamp + 100, 1, address(0));
  }

  function testListingRevertIfAlreadyListed() public {
    vm.startPrank(_owner);
    _escrow.listToken(address(_xerc20), block.timestamp + 100, 1, address(0));

    vm.expectRevert(OmniNetworkEscrow.OmniEscrow_AlreadyListed.selector);
    _escrow.listToken(address(_xerc20), block.timestamp + 100, 1, address(0));
    vm.stopPrank();
  }

  function testListingRevertIfTimestampIsNotInTheFuture() public {
    vm.startPrank(_owner);
    vm.expectRevert(OmniNetworkEscrow.OmniEscrow_DeadlineMustBeInTheFuture.selector);
    _escrow.listToken(address(_xerc20), block.timestamp, 1, address(0));
    vm.stopPrank();
  }

  function testListingRevertIfAmountToClaimIsZero() public {
    vm.startPrank(_owner);
    vm.expectRevert(OmniNetworkEscrow.OmniEscrow_TotalClaimableBiggerThanZero.selector);
    _escrow.listToken(address(_xerc20), block.timestamp + 1, 0, address(0));
    vm.stopPrank();
  }

  function testListing() public {
    vm.startPrank(_owner);
    _escrow.listToken(address(_xerc20), block.timestamp + 100, 1, address(0));
    vm.stopPrank();

    (uint256 claimDeadline, uint256 totalClaimable, address nftGated, uint256 totalClaimedWallets) =
      _escrow.listings(address(_xerc20));

    assertEq(claimDeadline, block.timestamp + 100);
    assertEq(totalClaimable, 1);
    assertEq(nftGated, address(0));
    assertEq(totalClaimedWallets, 0);

    assertEq(_escrow.getListingCount(), 1);
  }
}
