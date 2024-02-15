// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {Test} from 'forge-std/Test.sol';
import {XERC721} from '../../contracts/XERC721.sol';
import {IXERC721} from '../../interfaces/IXERC721.sol';

abstract contract Base is Test {
  address internal _owner = vm.addr(1);
  address internal _user = vm.addr(2);
  address internal _minter = vm.addr(3);

  XERC721 internal _xerc721;

  event BridgeLimitsSet(uint256 _mintingLimit, uint256 _burningLimit, address indexed _bridge);
  event LockboxSet(address _lockbox);
  event SetLimitsDelay(uint256 _delay);

  function setUp() public virtual {
    vm.startPrank(_owner);
    _xerc721 = new XERC721('Test', 'TST', _owner);
    vm.stopPrank();
  }
}

contract NftNames is Base {
  function testName() public {
    assertEq('Test', _xerc721.name());
  }

  function testSymbol() public {
    assertEq('TST', _xerc721.symbol());
  }
}

contract NftMintBurn is Base {
  function testMintRevertsIfNotApprove() public {
    vm.prank(_user);
    vm.expectRevert(IXERC721.IXERC721_NotHighEnoughLimits.selector);
    _xerc721.mint(_user, 1, '');
  }

  // TODO Apply batch
  // _amount0 = bound(_amount0, 1, 1e40);
  // _amount1 = bound(_amount1, 1, 1e40);
  // vm.assume(_amount1 > _amount0);
  function testBurnRevertsWhenLimitIsTooLow() public {
    vm.prank(_owner);
    _xerc721.setLimits(_user, 1, 0);

    vm.startPrank(_user);
    _xerc721.mint(_user, 1, 'Not allowed to burn URI');
    vm.expectRevert(IXERC721.IXERC721_NotHighEnoughLimits.selector);
    _xerc721.burn(_user, 1);
    vm.stopPrank();
  }

  // TODO Test batch mint
  // vm.assume(_amount > 0);
  function testMint() public {
    vm.prank(_owner);
    _xerc721.setLimits(_user, 1, 0);
    vm.prank(_user);
    _xerc721.mint(_minter, 1, '');

    assertEq(_xerc721.balanceOf(_minter), 1);
  }

  // TODO Test batch burn
  // _amount = bound(_amount, 1, 1e40);
  function testBurn() public {
    vm.startPrank(_owner);
    _xerc721.setLimits(_user, 1, 1);
    vm.stopPrank();

    vm.startPrank(_user);

    _xerc721.mint(_user, 1, '');
    _xerc721.burn(_user, 1);
    vm.stopPrank();

    assertEq(_xerc721.balanceOf(_user), 0);
  }

  function testBurnRevertsWithoutPreviousMint() public {
    vm.prank(_owner);
    _xerc721.setLimits(_owner, 1, 0);

    vm.startPrank(_owner);
    vm.expectRevert('ERC721: invalid token ID');
    _xerc721.burn(_user, 1);
    vm.stopPrank();

    assertEq(_xerc721.balanceOf(_user), 0);
  }
}

contract NftCreateParams is Base {
  function testChangeLimit(uint256 _amount, address _randomAddr) public {
    vm.assume(_randomAddr != address(0));
    vm.startPrank(_owner);
    _xerc721.setLimits(_randomAddr, _amount, _amount);
    vm.stopPrank();
    assertEq(_xerc721.mintingMaxLimitOf(_randomAddr), _amount);
    assertEq(_xerc721.burningMaxLimitOf(_randomAddr), _amount);
  }

  //   function testRevertsWithWrongCaller() public {
  //     vm.expectRevert('Ownable: caller is not the owner');
  //     _xerc721.setLimits(_minter, 1e18, 0);
  //   }

  //   function testAddingMintersAndLimits(
  //     uint256 _amount0,
  //     uint256 _amount1,
  //     uint256 _amount2,
  //     address _user0,
  //     address _user1,
  //     address _user2
  //   ) public {
  //     vm.assume(_amount0 > 0);
  //     vm.assume(_amount1 > 0);
  //     vm.assume(_amount2 > 0);

  //     vm.assume(_user0 != _user1 && _user1 != _user2 && _user0 != _user2);
  //     uint256[] memory _limits = new uint256[](3);
  //     address[] memory _minters = new address[](3);

  //     _limits[0] = _amount0;
  //     _limits[1] = _amount1;
  //     _limits[2] = _amount2;

  //     _minters[0] = _user0;
  //     _minters[1] = _user1;
  //     _minters[2] = _user2;

  //     vm.startPrank(_owner);
  //     for (uint256 _i = 0; _i < _minters.length; _i++) {
  //       _xerc721.setLimits(_minters[_i], _limits[_i], _limits[_i]);
  //     }
  //     vm.stopPrank();

  //     assertEq(_xerc721.mintingMaxLimitOf(_user0), _amount0);
  //     assertEq(_xerc721.mintingMaxLimitOf(_user1), _amount1);
  //     assertEq(_xerc721.mintingMaxLimitOf(_user2), _amount2);
  //     assertEq(_xerc721.burningMaxLimitOf(_user0), _amount0);
  //     assertEq(_xerc721.burningMaxLimitOf(_user1), _amount1);
  //     assertEq(_xerc721.burningMaxLimitOf(_user2), _amount2);
  //   }

  //   function testchangeBridgeMintingLimitEmitsEvent(uint256 _limit, address _minter) public {
  //     vm.prank(_owner);
  //     vm.expectEmit(true, true, true, true);
  //     emit BridgeLimitsSet(_limit, 0, _minter);
  //     _xerc721.setLimits(_minter, _limit, 0);
  //   }

  //   function testchangeBridgeBurningLimitEmitsEvent(uint256 _limit, address _minter) public {
  //     vm.prank(_owner);
  //     vm.expectEmit(true, true, true, true);
  //     emit BridgeLimitsSet(0, _limit, _minter);
  //     _xerc721.setLimits(_minter, 0, _limit);
  //   }

  //   function testSettingLimitsToUnapprovedUser(uint256 _amount) public {
  //     vm.assume(_amount > 0);

  //     vm.startPrank(_owner);
  //     _xerc721.setLimits(_minter, _amount, _amount);
  //     vm.stopPrank();

  //     assertEq(_xerc721.mintingMaxLimitOf(_minter), _amount);
  //     assertEq(_xerc721.burningMaxLimitOf(_minter), _amount);
  //   }

  //   function testUseLimitsUpdatesLimit(uint256 _limit, address _minter) public {
  //     vm.assume(_limit > 1e6);
  //     vm.assume(_minter != address(0));
  //     vm.warp(1_683_145_698); // current timestamp at the time of testing

  //     vm.startPrank(_owner);
  //     _xerc721.setLimits(_minter, _limit, _limit);
  //     vm.stopPrank();

  //     vm.startPrank(_minter);
  //     _xerc721.mint(_minter, _limit);
  //     _xerc721.burn(_minter, _limit);
  //     vm.stopPrank();

  //     assertEq(_xerc721.mintingMaxLimitOf(_minter), _limit);
  //     assertEq(_xerc721.mintingCurrentLimitOf(_minter), 0);
  //     assertEq(_xerc721.burningMaxLimitOf(_minter), _limit);
  //     assertEq(_xerc721.burningCurrentLimitOf(_minter), 0);
  //   }

  //   function testCurrentLimitIsMaxLimitIfUnused(uint256 _limit, address _minter) public {
  //     uint256 _currentTimestamp = 1_683_145_698;
  //     vm.warp(_currentTimestamp);

  //     vm.startPrank(_owner);
  //     _xerc721.setLimits(_minter, _limit, _limit);
  //     vm.stopPrank();

  //     vm.warp(_currentTimestamp + 12 hours);

  //     assertEq(_xerc721.mintingCurrentLimitOf(_minter), _limit);
  //     assertEq(_xerc721.burningCurrentLimitOf(_minter), _limit);
  //   }

  //   function testCurrentLimitIsMaxLimitIfOver24Hours(uint256 _limit, address _minter) public {
  //     uint256 _currentTimestamp = 1_683_145_698;
  //     vm.warp(_currentTimestamp);
  //     vm.assume(_minter != address(0));

  //     vm.startPrank(_owner);
  //     _xerc721.setLimits(_minter, _limit, _limit);
  //     vm.stopPrank();

  //     vm.startPrank(_minter);
  //     _xerc721.mint(_minter, _limit);
  //     _xerc721.burn(_minter, _limit);
  //     vm.stopPrank();

  //     vm.warp(_currentTimestamp + 30 hours);

  //     assertEq(_xerc721.mintingCurrentLimitOf(_minter), _limit);
  //     assertEq(_xerc721.burningCurrentLimitOf(_minter), _limit);
  //   }

  //   function testLimitVestsLinearly(uint256 _limit, address _minter) public {
  //     vm.assume(_limit > 1e6);
  //     vm.assume(_minter != address(0));
  //     uint256 _currentTimestamp = 1_683_145_698;
  //     vm.warp(_currentTimestamp);

  //     vm.startPrank(_owner);
  //     _xerc721.setLimits(_minter, _limit, _limit);
  //     vm.stopPrank();

  //     vm.startPrank(_minter);
  //     _xerc721.mint(_minter, _limit);
  //     _xerc721.burn(_minter, _limit);
  //     vm.stopPrank();

  //     vm.warp(_currentTimestamp + 12 hours);

  //     assertApproxEqRel(_xerc721.mintingCurrentLimitOf(_minter), _limit / 2, 0.1 ether);
  //     assertApproxEqRel(_xerc721.burningCurrentLimitOf(_minter), _limit / 2, 0.1 ether);
  //   }

  //   function testOverflowLimitMakesItMax(uint256 _limit, address _minter, uint256 _usedLimit) public {
  //     _limit = bound(_limit, 1e6, 100_000_000_000_000e18);
  //     vm.assume(_usedLimit < 1e3);
  //     vm.assume(_minter != address(0));
  //     uint256 _currentTimestamp = 1_683_145_698;
  //     vm.warp(_currentTimestamp);

  //     vm.startPrank(_owner);
  //     _xerc721.setLimits(_minter, _limit, _limit);
  //     vm.stopPrank();

  //     vm.startPrank(_minter);
  //     _xerc721.mint(_minter, _usedLimit);
  //     _xerc721.burn(_minter, _usedLimit);
  //     vm.stopPrank();

  //     vm.warp(_currentTimestamp + 20 hours);

  //     assertEq(_xerc721.mintingCurrentLimitOf(_minter), _limit);
  //     assertEq(_xerc721.burningCurrentLimitOf(_minter), _limit);
  //   }

  //   function testchangeBridgeMintingLimitIncreaseCurrentLimitByTheDifferenceItWasChanged(
  //     uint256 _limit,
  //     address _minter,
  //     uint256 _usedLimit
  //   ) public {
  //     vm.assume(_limit < 1e40);
  //     vm.assume(_usedLimit < 1e3);
  //     vm.assume(_limit > _usedLimit);
  //     vm.assume(_minter != address(0));
  //     uint256 _currentTimestamp = 1_683_145_698;
  //     vm.warp(_currentTimestamp);

  //     vm.startPrank(_owner);
  //     _xerc721.setLimits(_minter, _limit, _limit);
  //     vm.stopPrank();

  //     vm.startPrank(_minter);
  //     _xerc721.mint(_minter, _usedLimit);
  //     _xerc721.burn(_minter, _usedLimit);
  //     vm.stopPrank();

  //     vm.startPrank(_owner);
  //     // Adding 100k to the limit
  //     _xerc721.setLimits(_minter, _limit + 100_000, _limit + 100_000);
  //     vm.stopPrank();

  //     assertEq(_xerc721.mintingCurrentLimitOf(_minter), (_limit - _usedLimit) + 100_000);
  //   }

  //   function testchangeBridgeMintingLimitDecreaseCurrentLimitByTheDifferenceItWasChanged(
  //     uint256 _limit,
  //     address _minter,
  //     uint256 _usedLimit
  //   ) public {
  //     vm.assume(_minter != address(0));
  //     uint256 _currentTimestamp = 1_683_145_698;
  //     vm.warp(_currentTimestamp);
  //     _limit = bound(_limit, 1e15, 1e40);
  //     _usedLimit = bound(_usedLimit, 100_000, 1e9);

  //     vm.startPrank(_owner);
  //     // Setting the limit at its original limit
  //     _xerc721.setLimits(_minter, _limit, _limit);
  //     vm.stopPrank();

  //     vm.startPrank(_minter);
  //     _xerc721.mint(_minter, _usedLimit);
  //     _xerc721.burn(_minter, _usedLimit);
  //     vm.stopPrank();

  //     vm.startPrank(_owner);
  //     // Removing 100k to the limit
  //     _xerc721.setLimits(_minter, _limit - 100_000, _limit - 100_000);
  //     vm.stopPrank();

  //     assertEq(_xerc721.mintingCurrentLimitOf(_minter), (_limit - _usedLimit) - 100_000);
  //     assertEq(_xerc721.burningCurrentLimitOf(_minter), (_limit - _usedLimit) - 100_000);
  //   }

  //   function testChangingUsedLimitsToZero(uint256 _limit, uint256 _amount) public {
  //     _limit = bound(_limit, 1, 1e40);
  //     vm.assume(_amount < _limit);
  //     vm.startPrank(_owner);
  //     _xerc721.setLimits(_minter, _limit, _limit);
  //     vm.stopPrank();

  //     vm.startPrank(_minter);
  //     _xerc721.mint(_minter, _amount);
  //     _xerc721.burn(_minter, _amount);
  //     vm.stopPrank();

  //     vm.startPrank(_owner);
  //     _xerc721.setLimits(_minter, 0, 0);
  //     vm.stopPrank();

  //     assertEq(_xerc721.mintingMaxLimitOf(_minter), 0);
  //     assertEq(_xerc721.mintingCurrentLimitOf(_minter), 0);
  //     assertEq(_xerc721.burningMaxLimitOf(_minter), 0);
  //     assertEq(_xerc721.burningCurrentLimitOf(_minter), 0);
  //   }

  //   function testSetLockbox(address _lockbox) public {
  //     vm.prank(_owner);
  //     _xerc721.setLockbox(_lockbox);

  //     assertEq(_xerc721.lockbox(), _lockbox);
  //   }

  //   function testSetLockboxEmitsEvents(address _lockbox) public {
  //     vm.expectEmit(true, true, true, true);
  //     emit LockboxSet(_lockbox);
  //     vm.prank(_owner);
  //     _xerc721.setLockbox(_lockbox);
  //   }

  //   function testLockboxDoesntNeedMinterRights(address _lockbox) public {
  //     vm.assume(_lockbox != address(0));
  //     vm.prank(_owner);
  //     _xerc721.setLockbox(_lockbox);

  //     vm.startPrank(_lockbox);
  //     _xerc721.mint(_lockbox, 10);
  //     assertEq(_xerc721.balanceOf(_lockbox), 10);
  //     _xerc721.burn(_lockbox, 10);
  //     assertEq(_xerc721.balanceOf(_lockbox), 0);
  //     vm.stopPrank();
  //   }

  //   function testRemoveBridge(uint256 _limit) public {
  //     vm.assume(_limit > 0);

  //     vm.startPrank(_owner);
  //     _xerc721.setLimits(_minter, _limit, _limit);

  //     assertEq(_xerc721.mintingMaxLimitOf(_minter), _limit);
  //     assertEq(_xerc721.burningMaxLimitOf(_minter), _limit);
  //     _xerc721.setLimits(_minter, 0, 0);
  //     vm.stopPrank();

  //     assertEq(_xerc721.mintingMaxLimitOf(_minter), 0);
  //     assertEq(_xerc721.burningMaxLimitOf(_minter), 0);
  //   }
}
