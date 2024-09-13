# Passthrough Modules

This repo contains two passthroughmodules for Hats Protocol:

- [PassthroughModule](./src/PassthroughModule.sol): enables an authorized "criterion" hat to serve as the eligibility and/or toggle module for other hat(s), not compatible with module chaining.
- [HatControlledModule](./src/HatControlledModule.sol): enables an authorized "controller" hat to serve as the eligibility and/or toggle module for other hat(s), compatible with module chaining.

## 1. Passthrough Module

In Hats Protocol v1, eligibility and toggle modules are set as addresses. This creates a lot of flexibility, since addresses can be EOAs, multisigs, DAOs, or even other smart contracts. But hats themselves cannot be set explicitly as eligibility or toggle modules because hats are identified by a uint256 hatId, not an address.

Passthrough Module is a contract that can be set as the eligibility and/or toggle module for a target hat, and allows the wearer(s) of another hat to call the eligibility and/or toggle functions of the target hat. This allows hats themselves to be used as eligibility and toggle modules.

### Passthrough Eligibility

To use Passthrough Module as the eligibility module for a target hat, set Passthrough Module's address as the target hat's eligibility address.

Then, the wearer(s) of Passthrough Module's authorized `CRITERION_HAT` can call the `PassthroughEligibility.setHatWearerStatus()` function — which is a thin wrapper around `Hats.setHatWearerStatus()` — to push eligibility data to Hats Protocol.

### Passthrough Toggle

To use Passthrough Module as the toggle module for a target hat, set Passthrough Module's address as the target hat's toggle address.

Then, the wearer(s) of Passthrough Module's authorized `CRITERION_HAT` can call the `PassthroughToggle.setHatWearerStatus()` function — which is a thin wrapper around `Hats.setHatWearerStatus()` — to push toggle data to Hats Protocol.

## 2. Hat Controlled Module

Unlike Passthrough Module, Hat Controlled Module is compatible with module chaining. It achieves this by enabling a "controller" hat to set wearer status and hat status for a given target hat in the Hat Controlled Module contract, which Hats Protocol then pulls in when checking for wearers or status of the target hat.

### Hat Controlled Eligibility

To use Hat Controlled Module as the eligibility module for a target hat, set Hat Controlled Module's address as the target hat's eligibility address.

Then, the wearer(s) of the "controller" hat can call the `HatControlledModule.setWearerStatus()` function to set eligibility data for the target hat for Hats Protocol to pull.

### Hat Controlled Toggle

To use Hat Controlled Module as the toggle module for a target hat, set Hat Controlled Module's address as the target hat's toggle address.

Then, the wearer(s) of the "controller" hat can call the `HatControlledModule.setHatStatus()` function to set the toggle data for the target hat for Hats Protocol to pull.

## Development

This repo uses Foundry for development and testing. To get started:

1. Fork the project
2. Install [Foundry](https://book.getfoundry.sh/getting-started/installation)
3. To install dependencies, run `forge install`
4. To compile the contracts, run `forge build`
5. To test, run `forge test`
