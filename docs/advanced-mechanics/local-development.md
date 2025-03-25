# Forging Your Development Sanctuary 🏰

Welcome, master artificer! Here you'll learn how to establish your own realm for crafting and testing mystical contracts.

## Prerequisites 📚

Before beginning your journey, ensure you have these artifacts of power:

- [Foundry](https://book.getfoundry.sh/getting-started/installation.html) - The sacred forge
- [Git](https://git-scm.com/downloads) - The scroll keeper
- A compatible arcane terminal
- Your favorite enchanted code editor

## Setting Up Your Workspace 🔨

1. **Clone the Sacred Repository**
```bash
git clone https://github.com/your-username/defi-and-dragons.git
cd defi-and-dragons
```

2. **Install the Mystical Dependencies**
```bash
forge install
```

3. **Prepare the Test Environment**
```bash
# Copy the example environment scroll
cp .env.example .env

# Edit with your mystical secrets
vim .env
```

## The Sacred Environment Scroll (.env) 📜

```env
# The gateway to your test network
ETHEREUM_RPC_URL=

# Your secret enchanter's key (never share this!)
PRIVATE_KEY=

# Etherscan's blessing (for contract verification)
ETHERSCAN_API_KEY=
```

## Crafting (Building) the Contracts ⚒️

```bash
# Forge the contracts
forge build

# Forge with optimization
forge build --optimize
```

## Testing Your Creations 🧪

```bash
# Run all tests
forge test

# Run specific test file
forge test --match-path test/Character.t.sol

# Run with verbosity for debugging
forge test -vvv

# Run with gas reporting
forge test --gas-report
```

## Local Deployment 🚀

1. **Start Your Local Node**
```bash
# In a separate terminal
anvil
```

2. **Deploy to Local Network**
```bash
# Deploy with local configuration
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast
```

## Contract Verification 📋

After deploying to a public testnet:

```bash
forge verify-contract <CONTRACT_ADDRESS> src/Character.sol:Character \
    --chain-id <CHAIN_ID> \
    --constructor-args $(cast abi-encode "constructor(address,address)" <EQUIPMENT_ADDRESS> <RANDOM_ADDRESS>)
```

## Development Commands 🛠️

### Useful Forge Commands
```bash
# Check contract sizes
forge build --sizes

# Generate documentation
forge doc

# Run gas snapshots
forge snapshot

# Format code
forge fmt
```

### Testing with Coverage
```bash
# Generate coverage report
forge coverage

# Generate detailed HTML report
forge coverage --report lcov
genhtml lcov.info --output-directory coverage
```

## Troubleshooting Common Rituals 🔍

### Failed Dependencies
```bash
# Clean and reinstall dependencies
forge clean
forge install
```

### Test Network Issues
```bash
# Reset local node
anvil --reset

# Check network status
cast chain-id
```

### Contract Size Issues
```bash
# Check contract size
forge build --sizes

# If too large, optimize with:
forge build --optimize --optimizer-runs 1000
```

## Best Practices 📖

1. **Version Control**
   - Commit often
   - Use meaningful commit messages
   - Create feature branches

2. **Testing**
   - Write tests before code (TDD)
   - Aim for 100% coverage
   - Include both unit and integration tests

3. **Gas Optimization**
   - Monitor gas usage
   - Use gas snapshots
   - Optimize expensive operations

4. **Security**
   - Run slither analysis
   - Follow best practices
   - Consider formal verification

## Deployment Checklist ✅

Before deploying to mainnet:

- [ ] All tests passing
- [ ] Gas optimization complete
- [ ] Security audit performed
- [ ] Documentation updated
- [ ] Events properly emitted
- [ ] Error messages clear
- [ ] Contract size within limits

## Getting Help 🆘

- Join our [Discord](https://discord.gg/defi-dragons)
- Check [GitHub Issues](https://github.com/defi-dragons/issues)
- Review the [Foundry Book](https://book.getfoundry.sh/)

May your development journey be blessed with clean code and few bugs! 🙏✨ 