# DnD On-Chain Game

A decentralized role-playing game built on Ethereum using Foundry.

## Overview

This project implements a DnD-inspired on-chain game with the following features:
- Character NFTs with stats and equipment slots
- Equipment NFTs for weapons, armor, and accessories
- In-game currency (GOLD token)
- Quest system with rewards
- Random item drops using Chainlink VRF
- Marketplace for trading items

## Smart Contracts

- `Character.sol`: ERC721 contract for character NFTs
- `Equipment.sol`: ERC1155 contract for equipment NFTs
- `GameToken.sol`: ERC20 contract for in-game currency
- `Quest.sol`: Manages quests and rewards
- `ItemDrop.sol`: Handles random item drops using Chainlink VRF
- `Marketplace.sol`: Facilitates trading of equipment NFTs

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation.html)
- [Node.js](https://nodejs.org/) (for development tools)
- Ethereum wallet (e.g., MetaMask)
- Chainlink VRF subscription (for random item drops)

## Setup

1. Clone the repository:

```bash
git clone <repository-url>
cd dnd
```

2. Install dependencies:

```bash
forge install
```

3. Create a `.env` file with the following variables:

```
SEPOLIA_RPC_URL=your_sepolia_rpc_url
MAINNET_RPC_URL=your_mainnet_rpc_url
ETHERSCAN_API_KEY=your_etherscan_api_key
PRIVATE_KEY=your_deployer_private_key
VRF_COORDINATOR=chainlink_vrf_coordinator_address
VRF_SUBSCRIPTION_ID=your_vrf_subscription_id
VRF_KEY_HASH=your_vrf_key_hash
```

4. Compile contracts:

```bash
forge build
```

5. Run tests:

```bash
forge test
```

## Deployment

1. Deploy to Sepolia testnet:

```bash
forge script script/Deploy.s.sol:Deploy --rpc-url sepolia --broadcast --verify
```

2. Deploy to mainnet:

```bash
forge script script/Deploy.s.sol:Deploy --rpc-url mainnet --broadcast --verify
```

## Testing

The project includes comprehensive tests for all contracts. Run them with:

```bash
# Run all tests
forge test

# Run specific test file
forge test --match-path test/Character.t.sol

# Run with gas reporting
forge test --gas-report

# Run with verbosity
forge test -vvv
```

## Security

- All contracts use OpenZeppelin's battle-tested implementations
- Access control implemented using `Ownable`
- Chainlink VRF for secure randomness
- Reentrancy protection in marketplace transactions
- Comprehensive test coverage

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
