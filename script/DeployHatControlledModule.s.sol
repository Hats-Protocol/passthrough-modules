// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Script, console2 } from "forge-std/Script.sol";
import { HatControlledModule } from "../src/HatControlledModule.sol";

contract Deploy is Script {
  HatControlledModule public implementation;
  bytes32 public constant SALT = bytes32(abi.encode(0x4a75)); // ~ H(4) A(a) T(7) S(5)

  // default values
  bool internal _verbose = true;
  string internal _version = "0.1.0"; // initial version for HatControlledModule

  /// @dev Override default values, if desired
  function prepare(bool verbose, string memory version) public {
    _verbose = verbose;
    _version = version;
  }

  /// @dev Set up the deployer via their private key from the environment
  function deployer() public returns (address) {
    uint256 privKey = vm.envUint("PRIVATE_KEY");
    return vm.rememberKey(privKey);
  }

  function _log(string memory prefix) internal view {
    if (_verbose) {
      console2.log(string.concat(prefix, "Module:"), address(implementation));
    }
  }

  /// @dev Deploy the contract to a deterministic address via forge's create2 deployer factory.
  function run() public virtual {
    vm.startBroadcast(deployer());

    implementation = new HatControlledModule{ salt: SALT }(_version);

    vm.stopBroadcast();

    _log("");
  }
}

/* FORGE CLI COMMANDS

## A. Simulate the deployment locally
forge script script/DeployHatControlledModule.s.sol -f mainnet

## B. Deploy to real network and verify on etherscan
forge script script/DeployHatControlledModule.s.sol -f mainnet --broadcast --verify

## C. Fix verification issues (replace values in curly braces with the actual values)
forge verify-contract --chain-id 1 --num-of-optimizations 1000000 --watch --constructor-args $(cast abi-encode \
 "constructor(string)" "_version") \ 
 --compiler-version v0.8.19 {deploymentAddress} \
 src/HatControlledModule.sol:HatControlledModule --etherscan-api-key $ETHERSCAN_KEY

## D. To verify ir-optimized contracts on etherscan...
  1. Run (C) with the following additional flag: `--show-standard-json-input > etherscan.json`
  2. Patch `etherscan.json`: `"optimizer":{"enabled":true,"runs":100}` =>
`"optimizer":{"enabled":true,"runs":100},"viaIR":true`
  3. Upload the patched `etherscan.json` to etherscan manually

  See this github issue for more: https://github.com/foundry-rs/foundry/issues/3507#issuecomment-1465382107

*/
