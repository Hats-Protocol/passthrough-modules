// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test, console2 } from "forge-std/Test.sol";
import { PassthroughModule, NotAuthorized } from "../src/PassthroughModule.sol";
import { Deploy } from "../script/DeployPassthroughModule.s.sol";
import {
  HatsModuleFactory, IHats, deployModuleInstance, deployModuleFactory
} from "hats-module/utils/DeployFunctions.sol";
import { IHats } from "hats-protocol/Interfaces/IHats.sol";

contract PassthroughModuleTest is Deploy, Test {
  /// @dev variables inhereted from Deploy script
  // PassthroughModule public implementation;
  // bytes32 public SALT;

  uint256 public fork;
  uint256 public BLOCK_NUMBER = 19_467_227; // deployment block HatsModuleFactory v0.7.0
  IHats public HATS = IHats(0x3bc1A0Ad72417f2d411118085256fC53CBdDd137); // v1.hatsprotocol.eth
  HatsModuleFactory public factory = HatsModuleFactory(0x0a3f85fa597B6a967271286aA0724811acDF5CD9);
  uint256 public SALT_NONCE = 1;
  PassthroughModule public instance;
  bytes public otherImmutableArgs;
  bytes public initArgs;

  uint256 public tophat;
  uint256 public targetHat;
  uint256 public moduleHat;

  address public caller;
  address public org = makeAddr("org");
  address public eligibility = makeAddr("eligibility");
  address public toggle = makeAddr("toggle");
  address public wearer = makeAddr("wearer");
  address public nonWearer = makeAddr("nonWearer");

  string public MODULE_VERSION;

  // Hats.sol errors
  error NotHatsEligibility();
  error NotHatsToggle();

  function setUp() public virtual {
    // create and activate a fork, at BLOCK_NUMBER
    fork = vm.createSelectFork(vm.rpcUrl("mainnet"), BLOCK_NUMBER);

    // deploy implementation via the script
    prepare(false, MODULE_VERSION);
    run();
  }
}

contract WithInstanceTest is PassthroughModuleTest {
  function setUp() public virtual override {
    super.setUp();

    // set up the hats
    tophat = HATS.mintTopHat(org, "org's tophat", "");
    vm.startPrank(org);
    targetHat = HATS.createHat(tophat, "target hat", 2, address(999), address(999), true, "");
    HATS.mintHat(targetHat, wearer);
    moduleHat = HATS.createHat(tophat, "caller hat", 2, address(999), address(999), true, "");
    HATS.mintHat(moduleHat, eligibility);
    HATS.mintHat(moduleHat, toggle);
    vm.stopPrank();

    // we don't have any init args or immutable args
    otherImmutableArgs = abi.encodePacked(moduleHat);
    initArgs;

    // deploy an instance of the module
    instance = PassthroughModule(
      deployModuleInstance(factory, address(implementation), 0, otherImmutableArgs, initArgs, SALT_NONCE)
    );
  }

  modifier caller_(address _caller) {
    caller = _caller;
    vm.prank(caller);
    _;
  }
}

contract Deployment is WithInstanceTest {
  function test_initialization() public {
    // implementation
    vm.expectRevert("Initializable: contract is already initialized");
    implementation.setUp("setUp attempt");
    // instance
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

  function test_criterionHat() public view {
    assertEq(instance.CRITERION_HAT(), moduleHat);
  }
}

contract Eligibility is WithInstanceTest {
  modifier isEligibilityModule(bool _isModule) {
    if (_isModule) {
      vm.prank(org);
      HATS.changeHatEligibility(targetHat, address(instance));
    }
    _;
  }

  function test_happy() public isEligibilityModule(true) caller_(eligibility) {
    // revoke the hat by setting eligibility to false
    instance.setHatWearerStatus(targetHat, wearer, false, true);

    assertFalse(HATS.isWearerOfHat(wearer, targetHat));
  }

  function test_revert_nonWearer_isModule_cannotSetWearerStatus() public isEligibilityModule(true) caller_(nonWearer) {
    // attempt to revoke the hat, but revert because the caller is not wearing the hat
    vm.expectRevert(NotAuthorized.selector);
    instance.setHatWearerStatus(targetHat, wearer, false, true);

    assertTrue(HATS.isWearerOfHat(wearer, targetHat));
  }

  function test_revert_notModule_cannotSetWearerStatus() public isEligibilityModule(false) caller_(eligibility) {
    // attempt to revoke the hat, but revert because the instance is not set as the eligibility module
    vm.expectRevert(NotHatsEligibility.selector);
    instance.setHatWearerStatus(targetHat, wearer, false, true);

    assertTrue(HATS.isWearerOfHat(wearer, targetHat));
  }
}

contract Toggle is WithInstanceTest {
  modifier isToggleModule(bool _isModule) {
    if (_isModule) {
      vm.prank(org);
      HATS.changeHatToggle(targetHat, address(instance));
    }
    _;
  }

  function test_happy() public isToggleModule(true) caller_(toggle) {
    // set the hat status to false
    instance.setHatStatus(targetHat, false);

    // wearer should no longer be wearing the hat
    assertFalse(HATS.isWearerOfHat(wearer, targetHat));
  }

  function test_revert_nonWearer_isModule_cannotSetHatStatus() public isToggleModule(true) caller_(nonWearer) {
    // attempt to revoke the hat, but revert because the caller is not wearing the hat
    vm.expectRevert(NotAuthorized.selector);
    instance.setHatStatus(targetHat, false);

    assertTrue(HATS.isWearerOfHat(wearer, targetHat));
  }

  function test_revert_notModule_cannotSetHatStatus() public isToggleModule(false) caller_(toggle) {
    // attempt to revoke the hat, but revert because the instance is not set as the toggle module
    vm.expectRevert(NotHatsToggle.selector);
    instance.setHatStatus(targetHat, false);

    assertTrue(HATS.isWearerOfHat(wearer, targetHat));
  }
}
