// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test, console2 } from "forge-std/Test.sol";
import { HatControlledModule, NotAuthorized } from "../src/HatControlledModule.sol";
import { Deploy } from "../script/DeployHatControlledModule.s.sol";
import {
  HatsModuleFactory, IHats, deployModuleInstance, deployModuleFactory
} from "hats-module/utils/DeployFunctions.sol";
import { IHats } from "hats-protocol/Interfaces/IHats.sol";

contract HatControlledModuleTest is Deploy, Test {
  /// @dev variables inhereted from Deploy script
  // HatControlledModule public implementation;
  // bytes32 public SALT;

  uint256 public fork;
  uint256 public BLOCK_NUMBER = 19_467_227; // deployment block HatsModuleFactory v0.7.0
  IHats public HATS = IHats(0x3bc1A0Ad72417f2d411118085256fC53CBdDd137); // v1.hatsprotocol.eth
  HatsModuleFactory public factory = HatsModuleFactory(0x0a3f85fa597B6a967271286aA0724811acDF5CD9);
  uint256 public SALT_NONCE = 1;
  HatControlledModule public instance;
  bytes public otherImmutableArgs;
  bytes public initArgs;

  uint256 public tophat;
  uint256 public targetHat;
  uint256 public controllerHat;

  address public caller;
  address public controller = makeAddr("controller");
  address public org = makeAddr("org");
  address public wearer = makeAddr("wearer");
  address public nonWearer = makeAddr("nonWearer");

  string public MODULE_VERSION;

  event WearerStatusSet(address wearer, uint256 hatId, bool eligible, bool standing);
  event HatStatusSet(uint256 hatId, bool active);

  function setUp() public virtual {
    fork = vm.createSelectFork(vm.rpcUrl("mainnet"), BLOCK_NUMBER);

    prepare(false, MODULE_VERSION);
    run();
  }
}

contract WithInstanceTest is HatControlledModuleTest {
  function setUp() public virtual override {
    super.setUp();

    tophat = HATS.mintTopHat(org, "org's tophat", "");
    vm.startPrank(org);
    targetHat = HATS.createHat(tophat, "target hat", 2, address(999), address(999), true, "");
    controllerHat = HATS.createHat(tophat, "controller hat", 2, address(999), address(999), true, "");
    HATS.mintHat(controllerHat, controller);
    vm.stopPrank();

    otherImmutableArgs = abi.encodePacked(controllerHat);
    initArgs;

    instance = HatControlledModule(
      deployModuleInstance(factory, address(implementation), 0, otherImmutableArgs, initArgs, SALT_NONCE)
    );
  }

  function assertWearerStatus(address _wearer, uint256 _hatId, bool _eligible, bool _standing) public view {
    (bool eligible, bool standing) = instance.getWearerStatus(_wearer, _hatId);
    assertEq(standing, _standing);
    if (_standing) assertEq(eligible, _eligible);
    else assertFalse(eligible);
  }

  modifier caller_(address _caller) {
    caller = _caller;
    vm.prank(caller);
    _;
  }
}

contract Deployment is WithInstanceTest {
  function test_initialization() public {
    vm.expectRevert("Initializable: contract is already initialized");
    implementation.setUp("setUp attempt");
    vm.expectRevert("Initializable: contract is already initialized");
    instance.setUp("setUp attempt");
  }

  function test_version() public view {
    assertEq(instance.version(), MODULE_VERSION);
  }

  function test_implementation() public view {
    assertEq(address(instance.IMPLEMENTATION()), address(implementation));
  }

  function test_hats() public view {
    assertEq(address(instance.HATS()), address(HATS));
  }

  function test_hatId() public view {
    assertEq(instance.hatId(), 0);
  }

  function test_controllerHat() public view {
    assertEq(instance.CONTROLLER_HAT(), controllerHat);
  }
}

contract Eligibility is WithInstanceTest {
  function test_controller(address _wearer, uint256 _hatId, bool _eligible, bool _standing) public {
    // set a wearer's status
    vm.prank(controller);
    instance.setWearerStatus(_wearer, _hatId, _eligible, _standing);

    assertWearerStatus(_wearer, _hatId, _eligible, _standing);

    // set the same wearer's status for a different hat
    uint256 differentHat = uint256(keccak256(abi.encodePacked(_hatId)));

    vm.prank(controller);
    instance.setWearerStatus(_wearer, differentHat, _eligible, _standing);

    assertWearerStatus(_wearer, differentHat, _eligible, _standing);

    // set a different wearer's status for the first hat
    address otherWearer = address(bytes20(keccak256(abi.encodePacked(_wearer))));

    vm.prank(controller);
    instance.setWearerStatus(otherWearer, _hatId, _eligible, _standing);

    assertWearerStatus(otherWearer, _hatId, _eligible, _standing);
  }

  function test_emit_WearerStatusSet(address _wearer, uint256 _hatId, bool _eligible, bool _standing) public {
    vm.expectEmit(true, true, true, true);
    emit WearerStatusSet(_wearer, _hatId, _eligible, _standing);
    vm.prank(controller);
    instance.setWearerStatus(_wearer, _hatId, _eligible, _standing);
  }

  function test_default() public view {
    assertWearerStatus(wearer, targetHat, true, true);
  }

  function test_revert_nonController_cannotSetWearerStatus() public {
    vm.expectRevert(NotAuthorized.selector);
    vm.prank(nonWearer);
    instance.setWearerStatus(wearer, targetHat, false, true);
  }
}

contract Toggle is WithInstanceTest {
  function test_controller(uint256 _hatId, bool _status) public {
    vm.prank(controller);
    instance.setHatStatus(_hatId, _status);

    assertEq(instance.getHatStatus(_hatId), _status);

    // set a different hat's status
    uint256 differentHat = uint256(keccak256(abi.encodePacked(_hatId)));

    vm.prank(controller);
    instance.setHatStatus(differentHat, _status);

    assertEq(instance.getHatStatus(differentHat), _status);
  }

  function test_emit_HatStatusSet(uint256 _hatId, bool _status) public {
    vm.expectEmit(true, true, true, true);
    emit HatStatusSet(_hatId, _status);
    vm.prank(controller);
    instance.setHatStatus(_hatId, _status);
  }

  function test_default() public view {
    assertTrue(instance.getHatStatus(targetHat));
  }

  function test_revert_nonController_cannotSetHatStatus() public {
    vm.expectRevert(NotAuthorized.selector);
    vm.prank(nonWearer);
    instance.setHatStatus(targetHat, false);
  }
}
