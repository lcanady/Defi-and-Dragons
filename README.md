# Dungeons & DeFi

A decentralized role-playing game built on Ethereum that combines traditional RPG mechanics with DeFi elements. Players can create characters, collect equipment, complete quests, and participate in various DeFi activities, all while enjoying a classic RPG experience powered by blockchain technology.

## 🎮 Core Game Features

### Character System (Character.sol)
- Mint unique character NFTs (ERC-721)
- Customize character attributes (strength, agility, magic)
- Equip items to enhance stats
- Character progression through quests and activities

### Equipment System (Equipment.sol)
- Multi-token equipment system (ERC-1155)
- Various item types with unique stats and bonuses
- Special abilities and effects
- Equipment enhancement and modification

### Quest System (Quest.sol)
- Various quests with different difficulty levels
- Stat requirements for quest participation
- Token rewards for completion
- Cooldown periods to balance gameplay

### Item Drop System (ItemDrop.sol)
- Chainlink VRF-powered random drops
- Configurable drop tables and probabilities
- Fair and verifiable randomness
- Automatic item minting on successful drops

### Character Wallet (CharacterWallet.sol)
- Dedicated wallet for each character
- Secure asset management
- Simplified inventory system
- Character-specific transactions

## 💰 DeFi Components

### Game Token (GameToken.sol)
- Native ERC-20 token for the game ecosystem
- Used for rewards, transactions, and DeFi activities
- Earned through quests and gameplay
- Utility in marketplace and AMM

### Marketplace (Marketplace.sol)
- Trade characters, equipment, and items
- Set prices and create listings
- Auction system for rare items
- Fee structure for sustainability

### AMM System (amm/)
- Decentralized token exchange
- Liquidity provision opportunities
- Token swapping functionality
- Yield farming potential

## 🚀 Getting Started

### Prerequisites
- Node.js v14+
- Foundry
- MetaMask or compatible Web3 wallet

### Installation
1. Clone the repository:

```bash
git clone https://github.com/lcanady/dnd.git
cd dnd
```

2. Install dependencies:

```bash
forge install
```

3. Set up environment variables:

```bash
cp .env.example .env
# Edit .env with your values:
# - PRIVATE_KEY: Your deployment wallet private key
# - VRF_KEY_HASH: Chainlink VRF key hash
# - VRF_COORDINATOR: Chainlink VRF coordinator address
# - VRF_SUBSCRIPTION_ID: Your Chainlink VRF subscription ID
```

4. Run tests:

```bash
forge test
```

### Deployment
Deploy all contracts:

```bash
forge script script/Deploy.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```

## 🔧 Development

### Testing

```bash
# Run all tests
forge test

# Run specific test file
forge test --match-path test/Character.t.sol

# Run with verbosity for debugging
forge test -vv
```

### Contract Verification
After deployment, verify contracts on Etherscan:

```bash
forge verify-contract [CONTRACT_ADDRESS] [CONTRACT_NAME] --chain-id [CHAIN_ID] --api-key [ETHERSCAN_API_KEY]
```

## 🔐 Security Features

- OpenZeppelin's battle-tested contract implementations
- Chainlink VRF for verifiable randomness
- Access control and role-based permissions
- Reentrancy protection
- Integer overflow/underflow protection
- Emergency pause functionality
- Comprehensive test coverage

## 🛣️ Roadmap

### Phase 1 (Current)
- Core game mechanics
- Basic DeFi integration
- Character and equipment systems
- Quest system

### Phase 2 (Planned)
- Advanced character progression
- Guild system
- PvP battles
- Enhanced marketplace features

### Phase 3 (Future)
- Cross-chain functionality
- Advanced DeFi mechanics
- Governance system
- Mobile interface

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Solidity style guide
- Add comprehensive tests for new features
- Document all public functions
- Maintain gas efficiency
- Consider security implications

## 📄 License

MIT License - see LICENSE.md

## 🙏 Acknowledgments

- OpenZeppelin for secure contract implementations
- Chainlink for VRF functionality
- Foundry for development framework
- The Ethereum community for inspiration and support
