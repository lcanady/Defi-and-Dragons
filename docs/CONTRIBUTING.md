# Contributing to Arcane Game

## Overview
This guide outlines the development practices, code standards, and contribution workflow for the Arcane Game project. Our goal is to maintain high-quality, secure, and efficient smart contracts while fostering a collaborative development environment.

## Development Setup

### Environment Setup
1. Install required tools
   ```bash
   # Install Foundry
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   
   # Install development dependencies
   npm install -g solhint prettier prettier-plugin-solidity slither-analyzer
   
   # Install testing and security tools
   pip install mythril
   npm install -g eth-gas-reporter
   ```

2. Repository setup
   ```bash
   # Clone repository
   git clone https://github.com/lcanady/dnd.git
   cd dnd
   
   # Install dependencies
   forge install
   
   # Build contracts
   forge build
   
   # Run tests
   forge test
   ```

3. Environment configuration
   ```bash
   # Copy environment template
   cp .env.example .env
   
   # Required environment variables
   INFURA_API_KEY=           # Infura API key for deployments
   PRIVATE_KEY=              # Deployment wallet private key
   ETHERSCAN_API_KEY=        # For contract verification
   REPORT_GAS=true          # Enable gas reporting
   ```

## Development Workflow

### Branch Strategy
- `main` - Production-ready code, tagged releases only
- `develop` - Primary integration branch
- `feature/*` - New features and enhancements
- `fix/*` - Bug fixes and patches
- `refactor/*` - Code improvements and optimizations
- `docs/*` - Documentation updates
- `test/*` - Test additions or modifications

### Development Process
1. Feature Planning
   - Create detailed issue/ticket
   - Design technical specification
   - Review security implications
   - Plan test coverage

2. Implementation
   - Create feature branch
   - Implement core functionality
   - Add comprehensive tests
   - Optimize gas usage
   - Update documentation

3. Quality Assurance
   - Run full test suite
   - Perform gas optimization
   - Run security analysis
   - Update documentation

4. Code Review
   - Submit detailed PR
   - Address review feedback
   - Verify CI/CD checks
   - Obtain approvals

### Commit Guidelines
```
<type>(<scope>): <subject>

<body>

<footer>
```

Types:
- `feat`: New feature or enhancement
- `fix`: Bug fix
- `refactor`: Code restructuring
- `docs`: Documentation updates
- `test`: Test modifications
- `perf`: Performance improvements
- `chore`: Maintenance tasks
- `security`: Security improvements

Example:
```
feat(crafting): implement critical success system

- Add critical success probability calculation
- Implement bonus quality for critical success
- Add critical success events and modifiers
- Update tests and documentation
- Optimize gas usage for calculations

Closes #234
Gas savings: -15k per craft
Security: Medium impact, reviewed by @security-team
```

## Code Standards

### Smart Contract Structure
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/// @title Advanced Crafting System
/// @notice Manages the creation and enhancement of in-game items
/// @dev Implements upgradeable pattern with access control and security features
/// @custom:security-contact security@arcanegame.com
contract ArcaneCrafting is 
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    
    // Type declarations
    enum CraftingQuality { POOR, COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
    
    // State variables
    bytes32 public constant CRAFTER_ROLE = keccak256("CRAFTER_ROLE");
    uint256 private constant PRECISION = 10000;
    
    struct Recipe {
        uint256 id;
        uint256[] ingredients;
        uint256[] amounts;
        uint256 baseSuccessRate;
        uint256 criticalChance;
        bool isActive;
    }
    
    // Events
    event CraftingAttempt(
        uint256 indexed recipeId,
        address indexed crafter,
        bool success,
        bool critical,
        CraftingQuality quality
    );
    
    // Custom errors
    error InsufficientIngredients(uint256 required, uint256 available);
    error InvalidRecipe(uint256 recipeId);
    error CraftingLocked(address crafter);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize() public initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    
    // External functions
    function attemptCraft(
        uint256 recipeId,
        uint256[] calldata ingredientIds
    ) 
        external
        nonReentrant
        whenNotPaused
        onlyRole(CRAFTER_ROLE)
        returns (bool success, bool critical, CraftingQuality quality)
    {
        // Implementation
    }
}
```

### Testing Requirements

1. Test Structure
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/crafting/ArcaneCrafting.sol";
import "./mocks/MockIngredient.sol";

contract ArcaneCraftingTest is Test {
    ArcaneCrafting crafting;
    MockIngredient ingredients;
    
    // Test users
    address admin = address(1);
    address crafter = address(2);
    address user = address(3);
    
    function setUp() public {
        // Setup contracts
        vm.startPrank(admin);
        crafting = new ArcaneCrafting();
        crafting.initialize();
        ingredients = new MockIngredient();
        vm.stopPrank();
        
        // Setup roles
        vm.prank(admin);
        crafting.grantRole(crafting.CRAFTER_ROLE(), crafter);
        
        // Setup test data
        _setupTestRecipe();
    }
    
    function testCraftingSuccess() public {
        // Setup
        vm.startPrank(crafter);
        uint256[] memory ingredientIds = _prepareIngredients();
        
        // Execute
        (bool success, bool critical, CraftingQuality quality) = 
            crafting.attemptCraft(1, ingredientIds);
        
        // Verify
        assertTrue(success);
        assertEq(uint256(quality), uint256(CraftingQuality.COMMON));
        
        vm.stopPrank();
    }
    
    function testFuzzCrafting(
        uint256 seed,
        uint256[] calldata ingredients
    ) public {
        vm.assume(ingredients.length > 0);
        vm.assume(ingredients.length <= 10);
        
        // Property-based test implementation
    }
}
```

2. Coverage Requirements
   - 100% line coverage
   - 100% branch coverage
   - 100% function coverage
   - Critical path testing
   - Edge case coverage

3. Test Categories
   - Unit tests
   - Integration tests
   - Property-based tests
   - Stress tests
   - Gas optimization tests
   - Security tests

## Documentation Standards

### Code Documentation
1. NatSpec Documentation
```solidity
/// @title Contract title
/// @author Author name
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
/// @param name Explain the parameter
/// @return Explain the return value
/// @custom:security-contact security@example.com
```

2. Implementation Documentation
```solidity
function complexOperation(uint256 value) external returns (uint256) {
    // 1. Input validation
    require(value > 0, "Invalid value");
    
    // 2. Calculate intermediate result
    // Uses exponential scaling for precision
    uint256 intermediate = value.mul(PRECISION);
    
    // 3. Apply modifiers
    // Modifiers are applied in order of impact
    for (uint256 i = 0; i < modifiers.length; i++) {
        intermediate = _applyModifier(intermediate, modifiers[i]);
    }
    
    // 4. Final scaling and return
    return intermediate.div(PRECISION);
}
```

### Technical Documentation
1. System Documentation
   - Architecture overview
   - Component interaction
   - Data flow diagrams
   - State transitions

2. API Documentation
   - Function specifications
   - Event documentation
   - Error handling
   - Integration guides

## Pull Request Process

### PR Requirements
1. Code Quality
   - Passes all tests
   - Meets coverage requirements
   - Optimized gas usage
   - Clean linter results
   - Security review completed

2. Documentation
   - Updated technical docs
   - Added inline comments
   - Updated API documentation
   - Added test documentation

3. Review Process
   - 2 technical reviews
   - 1 security review
   - Gas optimization review
   - Documentation review

### PR Template
```markdown
## Description
Detailed description of changes

## Technical Details
- Implementation approach
- Architecture changes
- Security considerations
- Gas optimizations

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Property-based tests added
- [ ] Gas optimization verified
- [ ] Security tests passed

## Documentation
- [ ] Technical docs updated
- [ ] API docs updated
- [ ] Inline comments added
- [ ] Gas analysis added

## Security
- [ ] Security review completed
- [ ] No high/critical issues
- [ ] Audit recommendations addressed

## Performance
- [ ] Gas optimization completed
- [ ] Benchmark results added
- [ ] Performance impact analyzed

## Checklist
- [ ] Tests pass
- [ ] Coverage maintained
- [ ] Gas optimized
- [ ] Documentation complete
- [ ] Security verified
```

## Deployment Process

### Preparation
1. Version Control
   - Update version numbers
   - Update changelog
   - Tag release

2. Security
   - Complete security audit
   - Fix all critical issues
   - Update security docs

3. Documentation
   - Update deployment guides
   - Update integration docs
   - Prepare release notes

### Deployment Steps
1. Testnet Deployment
   - Deploy to test network
   - Run integration tests
   - Verify contracts
   - Monitor performance

2. Mainnet Deployment
   - Deploy proxy contracts
   - Initialize systems
   - Verify contracts
   - Set up monitoring

3. Post-Deployment
   - Monitor transactions
   - Track gas usage
   - Watch for errors
   - Update documentation

## Support and Resources

### Development Support
- GitHub Issues
- Technical Documentation
- Security Guidelines
- Gas Optimization Guide

### Community Resources
- Discord Development Channel
- Technical Blog
- Security Advisories
- Gas Usage Reports 