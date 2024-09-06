// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// import { console2 } from "forge-std/Test.sol"; // remove before deploy
import { HatsEligibilityModule, HatsModule } from "hats-module/HatsEligibilityModule.sol";
import { HatsToggleModule } from "hats-module/HatsToggleModule.sol";

/*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
//////////////////////////////////////////////////////////////*/

/// @notice Thrown when the caller is not wearing the {hatId} hat
error NotAuthorized();

/**
 * @title HatControlledModule
 * @author spengrah
 * @author Haberdasher Labs
 * @notice This module allows the wearer(s) of a given "criterion" hat to serve as the eligibilty and/or toggle module
 * for a different hat. It is compatible with module chaining.
 * @dev This contract inherits from HatsModule, and is intended to be deployed as minimal proxy clone(s) via
 * HatsModuleFactory. For this contract to be used, it must be set as either the eligibility or toggle module for
 * another hat.
 */
contract HatControlledModule is HatsEligibilityModule, HatsToggleModule {
  /*//////////////////////////////////////////////////////////////
                            DATA MODELS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Ineligibility and standing data for an account, defaulting to positives.
   * @param ineligible Whether the account is ineligible to wear the hat. Defaults to eligible.
   * @param badStanding Whether the account is in bad standing for the hat. Defaults to good standing.
   */
  struct IneligibilityData {
    bool ineligible;
    bool badStanding;
  }

  /*//////////////////////////////////////////////////////////////
                            CONSTANTS 
  //////////////////////////////////////////////////////////////*/

  /**
   * This contract is a clone with immutable args, which means that it is deployed with a set of
   * immutable storage variables (ie constants). Accessing these constants is cheaper than accessing
   * regular storage variables (such as those set on initialization of a typical EIP-1167 clone),
   * but requires a slightly different approach since they are read from calldata instead of storage.
   *
   * Below is a table of constants and their location.
   *
   * For more, see here: https://github.com/Saw-mon-and-Natalie/clones-with-immutable-args
   *
   * ----------------------------------------------------------------------+
   * CLONE IMMUTABLE "STORAGE"                                             |
   * ----------------------------------------------------------------------|
   * Offset  | Constant          | Type    | Length  | Source              |
   * ----------------------------------------------------------------------|
   * 0       | IMPLEMENTATION    | address | 20      | HatsModule          |
   * 20      | HATS              | address | 20      | HatsModule          |
   * 40      | hatId             | uint256 | 32      | HatsModule          |
   * 72      | CRITERION_HAT     | uint256 | 32      | PassthroughModule   |
   * ----------------------------------------------------------------------+
   */
  function CRITERION_HAT() public pure returns (uint256) {
    return _getArgUint256(72);
  }

  /*//////////////////////////////////////////////////////////////
                            MUTABLE STORAGE 
  //////////////////////////////////////////////////////////////*/

  /// @notice Ineligibility and standing data for a given hat and wearer, defaulting to eligible and good standing
  mapping(uint256 hatId => mapping(address wearer => IneligibilityData ineligibility)) internal wearerIneligibility;

  /// @notice Status of a given hat
  mapping(uint256 hatId => bool inactive) internal hatInactivity;

  /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
  //////////////////////////////////////////////////////////////*/

  /// @notice Deploy the implementation contract and set its version
  /// @dev This is only used to deploy the implementation contract, and should not be used to deploy clones
  constructor(string memory _version) HatsModule(_version) { }

  /*//////////////////////////////////////////////////////////////
                            INITIALIZER
  //////////////////////////////////////////////////////////////*/

  /// @inheritdoc HatsModule
  function _setUp(bytes calldata) internal override {
    // no initial values to set
  }

  /*//////////////////////////////////////////////////////////////
                          ELIGIBILITY FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Set the eligibility status of a `_hatId` for a `_wearer`, in this contract. When this contract is set as
   * the eligibility module for that `hatId`, including as part of a module chain, Hats Protocol will pull this data
   * when checking the wearer's eligibility.
   * @dev Only callable by the wearer(s) of the {hatId} hat.
   * @param _wearer The address to set the eligibility status for
   * @param _hatId The hat to set the eligibility status for
   * @param _eligible The new _wearer's eligibility, where TRUE = eligible
   * @param _standing The new _wearer's standing, where TRUE = in good standing
   */
  function setWearerStatus(address _wearer, uint256 _hatId, bool _eligible, bool _standing) public onlyController {
    wearerIneligibility[_hatId][_wearer] = IneligibilityData(!_eligible, !_standing);
  }

  /// @inheritdoc HatsEligibilityModule
  function getWearerStatus(address _wearer, uint256 _hatId) public view override returns (bool eligible, bool standing) {
    IneligibilityData memory data = wearerIneligibility[_hatId][_wearer];
    return (!data.ineligible, !data.badStanding);
  }

  /*//////////////////////////////////////////////////////////////
                          TOGGLE FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Toggle the status of `_hatId` in this contract. When this contract is set as the toggle module for that
   * `hatId`, including as part of a module chain, Hats Protocol will pull this data when checking the status of the
   * hat.
   * @dev Only callable by the wearer(s) of the {hatId} hat.
   * @param _hatId The hat to set the status for
   * @param _newStatus The new status, where TRUE = active
   */
  function setHatStatus(uint256 _hatId, bool _newStatus) public onlyController {
    hatInactivity[_hatId] = !_newStatus;
  }

  /// @inheritdoc HatsToggleModule
  function getHatStatus(uint256 _hatId) public view override returns (bool active) {
    return !hatInactivity[_hatId];
  }

  /*//////////////////////////////////////////////////////////////
                            MODIFIERS
  //////////////////////////////////////////////////////////////*/

  /// @notice Reverts if the caller is not wearing the {hatId} hat
  modifier onlyController() {
    if (!HATS().isWearerOfHat(msg.sender, CRITERION_HAT())) revert NotAuthorized();
    _;
  }
}
