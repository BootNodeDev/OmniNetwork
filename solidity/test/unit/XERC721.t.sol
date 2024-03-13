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
    _xerc721.mint(_user, '');
  }

  function testBurnRevertsWhenLimitIsTooLow() public {
    vm.prank(_owner);
    _xerc721.setLimits(_user, 1, 0);

    vm.startPrank(_user);
    _xerc721.mint(_user, 'Not allowed to burn URI');
    vm.expectRevert(IXERC721.IXERC721_NotHighEnoughLimits.selector);
    _xerc721.burn(_user, 0);
    vm.stopPrank();
  }

  function testMint() public {
    vm.prank(_owner);
    _xerc721.setLimits(_user, 1, 0);
    vm.prank(_user);
    _xerc721.mint(_minter, '');

    assertEq(_xerc721.balanceOf(_minter), 1);
  }

  function testBurn() public {
    vm.startPrank(_owner);
    _xerc721.setLimits(_user, 1, 1);
    vm.stopPrank();

    vm.startPrank(_user);

    _xerc721.mint(_user, '');
    _xerc721.burn(_user, 0);
    vm.stopPrank();

    assertEq(_xerc721.balanceOf(_user), 0);
  }

  function testBurnRevertsWithoutPreviousMint() public {
    vm.prank(_owner);
    _xerc721.setLimits(_owner, 1, 0);

    vm.startPrank(_owner);
    vm.expectRevert('ERC721: invalid token ID');
    _xerc721.burn(_user, 0);
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

  function testRevertsWithWrongCaller() public {
    vm.expectRevert('Ownable: caller is not the owner');
    _xerc721.setLimits(_minter, 1e18, 0);
  }

  function testAddingMintersAndLimits(
    uint256 _amount0,
    uint256 _amount1,
    uint256 _amount2,
    address _user0,
    address _user1,
    address _user2
  ) public {
    vm.assume(_amount0 > 0);
    vm.assume(_amount1 > 0);
    vm.assume(_amount2 > 0);

    vm.assume(_user0 != _user1 && _user1 != _user2 && _user0 != _user2);
    uint256[3] memory _limits = [_amount0, _amount1, _amount2];
    address[3] memory _minters = [_user0, _user1, _user2];

    vm.startPrank(_owner);
    for (uint256 _i = 0; _i < _minters.length; _i++) {
      _xerc721.setLimits(_minters[_i], _limits[_i], _limits[_i]);
    }
    vm.stopPrank();

    assertEq(_xerc721.mintingMaxLimitOf(_user0), _amount0);
    assertEq(_xerc721.mintingMaxLimitOf(_user1), _amount1);
    assertEq(_xerc721.mintingMaxLimitOf(_user2), _amount2);
    assertEq(_xerc721.burningMaxLimitOf(_user0), _amount0);
    assertEq(_xerc721.burningMaxLimitOf(_user1), _amount1);
    assertEq(_xerc721.burningMaxLimitOf(_user2), _amount2);
  }

  function testchangeBridgeMintingLimitEmitsEvent(uint256 _limit, address _minter) public {
    vm.prank(_owner);
    vm.expectEmit(true, true, true, true);
    emit BridgeLimitsSet(_limit, 0, _minter);
    _xerc721.setLimits(_minter, _limit, 0);
  }

  function testchangeBridgeBurningLimitEmitsEvent(uint256 _limit, address _minter) public {
    vm.prank(_owner);
    vm.expectEmit(true, true, true, true);
    emit BridgeLimitsSet(0, _limit, _minter);
    _xerc721.setLimits(_minter, 0, _limit);
  }

  function testSettingLimitsToUnapprovedUser(uint256 _amount) public {
    vm.assume(_amount > 0);

    vm.startPrank(_owner);
    _xerc721.setLimits(_minter, _amount, _amount);
    vm.stopPrank();

    assertEq(_xerc721.mintingMaxLimitOf(_minter), _amount);
    assertEq(_xerc721.burningMaxLimitOf(_minter), _amount);
  }

  function testUseLimitsUpdatesLimit(address _minter) public {
    vm.assume(_minter != address(0));

    vm.startPrank(_owner);
    _xerc721.setLimits(_minter, 5, 5);
    vm.stopPrank();

    uint256[] memory newIds = new uint256[](5);
    for (uint256 i = 0; i < 5; i++) {
      newIds[i] = i;
    }
    vm.startPrank(_minter);
    _xerc721.mintBatch(_minter, new string[](5));
    _xerc721.burnBatch(_minter, newIds);
    vm.stopPrank();

    assertEq(_xerc721.mintingMaxLimitOf(_minter), 5);
    assertEq(_xerc721.mintingCurrentLimitOf(_minter), 0);
    assertEq(_xerc721.burningMaxLimitOf(_minter), 5);
    assertEq(_xerc721.burningCurrentLimitOf(_minter), 0);
  }

  function testCurrentLimitIsMaxLimitIfUnused(uint256 _limit, address _minter) public {
    uint256 _currentTimestamp = 1_683_145_698;
    vm.warp(_currentTimestamp);

    vm.startPrank(_owner);
    _xerc721.setLimits(_minter, _limit, _limit);
    vm.stopPrank();

    vm.warp(_currentTimestamp + 12 hours);

    assertEq(_xerc721.mintingCurrentLimitOf(_minter), _limit);
    assertEq(_xerc721.burningCurrentLimitOf(_minter), _limit);
  }

  function testCurrentLimitIsMaxLimitIfOver24Hours(address _minter) public {
    vm.assume(_minter != address(0));

    vm.startPrank(_owner);
    _xerc721.setLimits(_minter, 5, 5);
    vm.stopPrank();

    uint256[] memory newIds = new uint256[](5);
    for (uint256 i = 0; i < 5; i++) {
      newIds[i] = i;
    }
    vm.startPrank(_minter);
    _xerc721.mintBatch(_minter, new string[](5));
    _xerc721.burnBatch(_minter, newIds);
    vm.stopPrank();

    vm.warp(block.timestamp + 30 hours);

    assertEq(_xerc721.mintingMaxLimitOf(_minter), 5);
    assertEq(_xerc721.mintingCurrentLimitOf(_minter), 5);
    assertEq(_xerc721.burningMaxLimitOf(_minter), 5);
    assertEq(_xerc721.burningCurrentLimitOf(_minter), 5);
  }

  function testchangeBridgeMintingLimitIncreaseCurrentLimitByTheDifferenceItWasChanged(
    uint256 _limit,
    address _minter
  ) public {
    _limit = bound(_limit, 5, 50);

    vm.assume(_minter != address(0));

    vm.startPrank(_owner);
    _xerc721.setLimits(_minter, _limit, _limit);
    vm.stopPrank();

    vm.startPrank(_minter);
    uint256[] memory newIds = new uint256[](5);
    for (uint256 i = 0; i < 5; i++) {
      newIds[i] = i;
    }
    _xerc721.mintBatch(_minter, new string[](5));
    _xerc721.burnBatch(_minter, newIds);
    vm.stopPrank();

    vm.startPrank(_owner);
    // Adding 100k to the limit
    _xerc721.setLimits(_minter, _limit + 100_000, _limit + 100_000);
    vm.stopPrank();

    assertEq(_xerc721.mintingCurrentLimitOf(_minter), (_limit - 5) + 100_000);
    assertEq(_xerc721.burningCurrentLimitOf(_minter), (_limit - 5) + 100_000);
  }

  function testchangeBridgeMintingLimitDecreaseCurrentLimitByTheDifferenceItWasChanged(
    uint256 _limit,
    address _minter
  ) public {
    vm.assume(_limit >= 10);
    vm.assume(_minter != address(0));
    uint256 diffLimit = 2;

    vm.startPrank(_owner);
    _xerc721.setLimits(_minter, _limit, _limit);
    vm.stopPrank();

    vm.startPrank(_minter);
    uint256[] memory newIds = new uint256[](5);
    for (uint256 i = 0; i < 5; i++) {
      newIds[i] = i;
    }
    _xerc721.mintBatch(_minter, new string[](5));
    _xerc721.burnBatch(_minter, newIds);
    vm.stopPrank();

    vm.startPrank(_owner);
    // Removing diffLimit to the limit
    _xerc721.setLimits(_minter, _limit - diffLimit, _limit - diffLimit);
    vm.stopPrank();

    assertEq(_xerc721.mintingCurrentLimitOf(_minter), (_limit - 5) - diffLimit);
    assertEq(_xerc721.burningCurrentLimitOf(_minter), (_limit - 5) - diffLimit);
  }

  function testChangingUsedLimitsToZero(uint256 _limit) public {
    _limit = bound(_limit, 5, 1e40);
    vm.startPrank(_owner);
    _xerc721.setLimits(_minter, _limit, _limit);
    vm.stopPrank();

    vm.startPrank(_minter);
    uint256[] memory newIds = new uint256[](5);
    for (uint256 i = 0; i < 5; i++) {
      newIds[i] = i;
    }

    _xerc721.mintBatch(_minter, new string[](5));
    _xerc721.burnBatch(_minter, newIds);
    vm.stopPrank();

    vm.startPrank(_owner);
    _xerc721.setLimits(_minter, 0, 0);
    vm.stopPrank();

    assertEq(_xerc721.mintingMaxLimitOf(_minter), 0);
    assertEq(_xerc721.mintingCurrentLimitOf(_minter), 0);
    assertEq(_xerc721.burningMaxLimitOf(_minter), 0);
    assertEq(_xerc721.burningCurrentLimitOf(_minter), 0);
  }

  function testRemoveBridge(uint256 _limit) public {
    vm.assume(_limit > 0);

    vm.startPrank(_owner);
    _xerc721.setLimits(_minter, _limit, _limit);

    assertEq(_xerc721.mintingMaxLimitOf(_minter), _limit);
    assertEq(_xerc721.burningMaxLimitOf(_minter), _limit);
    _xerc721.setLimits(_minter, 0, 0);
    vm.stopPrank();

    assertEq(_xerc721.mintingMaxLimitOf(_minter), 0);
    assertEq(_xerc721.burningMaxLimitOf(_minter), 0);
  }
}
