# Passthrough Module

A [Hats Protocol](https://github.com/hats-protocol/hats-protocol) module that enables an authorized hat to serve as the eligibility and/or toggle module for other hat(s).

## Overview and Usage

In Hats Protocol v1, eligibility and toggle modules are set as addresses. This creates a lot of flexibility, since addresses can be EOAs, multisigs, DAOs, or even other smart contracts. But hats themselves cannot be set explicitly as eligibility or toggle modules because hats are identified by a uint256 hatId, not an address.

Passthrough Module is a contract that can be set as the eligibility and/or toggle module for a target hat, and allows the wearer(s) of another hat to call the eligibility and/or toggle functions of the target hat. This allows hats themselves to be used as eligibility and toggle modules.

This contract is a "humanistic" module, not a "mechanistic" module. It does not inherit from `IHatsEligibility.sol` or `IHatsToggle.sol`, so Hats Protocol cannot pull any data from it. It serves only as a passthrough, enabling the wearer(s) of the authorized hat to push eligibility and toggle data about the target hat to Hats Protocol. 

### Passthrough Eligibility

To use Passthrough Module as the eligibility module for a target hat, set Passthrough Module's address as the target hat's eligibility address.

Then, the wearer(s) of Passthrough Module's authorized hat can call the `PassthroughEligibility.setHatWearerStatus()` function — which is a thin wrapper around `Hats.setHatWearerStatus()` — to push eligibility data to Hats Protocol. 

### Passthrough Toggle

To use Passthrough Module as the toggle module for a target hat, set Passthrough Module's address as the target hat's toggle address.

Then, the wearer(s) of Passthrough Module's authorized hat can call the `PassthroughToggle.setHatWearerStatus()` function — which is a thin wrapper around `Hats.setHatWearerStatus()` — to push toggle data to Hats Protocol.

## Development

This repo uses Foundry for development and testing. To get started:

1. Fork the project
2. Install [Foundry](https://book.getfoundry.sh/getting-started/installation)
3. To install dependencies, run `forge install`
4. To compile the contracts, run `forge build`
5. To test, run `forge test`
