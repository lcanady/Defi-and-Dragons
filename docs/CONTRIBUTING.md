# Contributing Guide

## Development Setup

### Environment
1. Install dependencies
   ```bash
   # Core tools
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   
   # Dev dependencies
   npm install -g solhint prettier prettier-plugin-solidity
   ```

2. Clone and setup
   ```bash
   git clone https://github.com/lcanady/dnd.git
   cd dnd
   forge install
   ```

3. Configure environment
   ```bash
   cp .env.example .env
   # Edit .env with required values
   ```

## Development Workflow

### 1. Branch Strategy
- `main` - Production-ready code
- `develop` - Integration branch
- `feature/*` - New features
- `fix/*` - Bug fixes
- `refactor/*` - Code improvements

### 2. Development Process
1. Create feature branch
2. Implement changes
3. Add tests
4. Update documentation
5. Submit PR

### 3. Commit Guidelines
```
<type>(<scope>): <subject>

<body>

<footer>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code change
- `docs`: Documentation
- `test`: Test changes
- `chore`: Maintenance

Example:
```
feat(character): add equipment bonuses

- Implement stat bonus calculations
- Add equipment slot validation
- Update tests

Closes #123
```

## Code Standards

### Solidity Style
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @title Character Contract
/// @notice Manages game characters
/// @dev Implements ERC721 for character NFTs
contract Character is ERC721 {
    // State variables
    uint256 private _nextId;
    
    // Events
    event CharacterCreated(uint256 indexed id);
    
    // Custom errors
    error InvalidCharacter();
    
    // Constructor
    constructor() ERC721("Character", "CHAR") {}
    
    // External functions
    function mint() external returns (uint256) {
        uint256 id = _nextId++;
        _safeMint(msg.sender, id);
        emit CharacterCreated(id);
        return id;
    }
}
```

### Testing Requirements
1. 100% test coverage
2. Unit tests for all functions
3. Integration tests for workflows
4. Fuzz testing for complex logic
5. Gas optimization tests

Example:
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Character.sol";

contract CharacterTest is Test {
    Character character;
    
    function setUp() public {
        character = new Character();
    }
    
    function testMint() public {
        uint256 id = character.mint();
        assertEq(character.ownerOf(id), address(this));
    }
    
    function testFuzzMint(address user) public {
        vm.assume(user != address(0));
        vm.prank(user);
        uint256 id = character.mint();
        assertEq(character.ownerOf(id), user);
    }
}
```

## Documentation

### Code Documentation
- NatSpec comments for all contracts
- Inline comments for complex logic
- Event and error documentation
- Gas considerations noted

### Technical Documentation
- Update API docs for changes
- Document new features
- Update architecture diagrams
- Note breaking changes

## Pull Request Process

### 1. Preparation
- Rebase on latest `develop`
- Run full test suite
- Update documentation
- Check gas optimizations

### 2. PR Template
```markdown
## Description
Brief description of changes

## Changes
- Detailed list of changes
- Technical implementation notes
- Breaking changes

## Testing
- [ ] Unit tests
- [ ] Integration tests
- [ ] Gas optimization tests
- [ ] Documentation updates

## Checklist
- [ ] Tests pass
- [ ] Documentation updated
- [ ] Gas optimized
- [ ] No linter errors
```

### 3. Review Process
1. Automated checks
   - Tests pass
   - Coverage maintained
   - Linting clean
   - Gas optimized

2. Code review
   - Security review
   - Logic verification
   - Style compliance
   - Documentation check

3. Approval requirements
   - 2 core team reviews
   - All checks pass
   - No blocking issues

## Release Process

### 1. Version Bump
- Update version in contracts
- Update changelog
- Tag release

### 2. Deployment
- Deploy to testnet
- Verify contracts
- Run integration tests
- Deploy to mainnet

### 3. Post-Release
- Update documentation
- Announce changes
- Monitor deployment

## Support

### Getting Help
- GitHub Issues
- Discord community
- Technical docs
- Core team contact

### Reporting Issues
1. Check existing issues
2. Include reproduction steps
3. Provide environment details
4. Add relevant logs
5. Suggest fix if possible 