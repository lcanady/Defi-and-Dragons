## Defi-and-Dragons TypeScript SDK Architecture

### Core Architecture Principles

1. **Service-Based Architecture**
   - Each major game component should be encapsulated in its own service
   - Services should be loosely coupled and highly cohesive
   - Use dependency injection for service composition
   - Implement interface-first design

2. **Module Structure**
```typescript
src/
├── core/                     // Core functionality and base classes
│   ├── types/               // TypeScript types and interfaces
│   ├── constants/           // Game constants and configurations
│   ├── errors/             // Custom error classes
│   └── utils/              // Utility functions
├── services/               // Service implementations
│   ├── character/          // Character-related services
│   ├── equipment/          // Equipment management
│   ├── quest/             // Quest system
│   ├── marketplace/        // Trading and auction services
│   ├── defi/              // DeFi-related services
│   ├── guild/             // Guild and DAO services
│   └── game/              // Game mechanics and state management
├── contracts/             // Contract interfaces and ABIs
├── config/               // Configuration management
└── index.ts             // Main entry point
```

3. **Service Interface Standards**
```typescript
// Example service interface pattern
interface ICharacterService {
  // Core methods
  initialize(): Promise<void>;
  destroy(): Promise<void>;
  
  // State management
  getState(): Promise<CharacterState>;
  
  // Event handling
  on(event: CharacterEvent, callback: (data: any) => void): void;
  off(event: CharacterEvent, callback: (data: any) => void): void;
}
```

### Implementation Guidelines

1. **Core Services**

```typescript
// Base service class
abstract class BaseService {
  protected provider: ethers.providers.Provider;
  protected signer: ethers.Signer;
  
  constructor(config: ServiceConfig) {
    this.provider = config.provider;
    this.signer = config.signer;
  }
  
  abstract initialize(): Promise<void>;
}

// Service factory
class ServiceFactory {
  static createCharacterService(config: ServiceConfig): ICharacterService;
  static createEquipmentService(config: ServiceConfig): IEquipmentService;
  // ... other service creators
}
```

2. **Error Handling**

```typescript
// Custom error types
class SDKError extends Error {
  constructor(message: string, public code: string) {
    super(message);
  }
}

class ContractError extends SDKError {
  constructor(message: string, public txHash?: string) {
    super(message, 'CONTRACT_ERROR');
  }
}
```

3. **Configuration Management**

```typescript
// Simple, user-friendly configuration
interface SDKConfig {
  // Connect with MetaMask/Web3 wallet (browser)
  wallet?: 'metamask' | 'walletconnect';
  
  // OR connect with private key (node.js/backend)
  privateKey?: string;
  
  // Required network settings
  network: {
    // Network name or chain ID (e.g. 'mainnet', 'sepolia', 1, 11155111)
    name: string | number;
    // Optional custom RPC URL (defaults to public RPC for the network)
    rpcUrl?: string;
  };
}

// Internal configuration (handled by SDK)
interface InternalConfig {
  provider: ethers.providers.Provider;
  signer: ethers.Signer;
  contracts: {
    [key: string]: string;
  };
  options?: {
    gasLimit?: number;
    maxFeePerGas?: number;
    maxPriorityFeePerGas?: number;
  };
}
```

### Usage Examples

```typescript
// 1. Browser with MetaMask (simplest)
const sdk = new DefiAndDragonsSDK({
  wallet: 'metamask',
  network: { name: 'sepolia' }
});

// 2. Backend with private key
const sdk = new DefiAndDragonsSDK({
  privateKey: process.env.PRIVATE_KEY,
  network: {
    name: 'mainnet',
    rpcUrl: 'https://eth-mainnet.g.alchemy.com/v2/your-api-key'
  }
});

// Using the SDK is the same for both connection types
const game = await sdk.connect();

// All game interactions are now available through a simple interface
const character = await game.characters.mint();
const quests = await game.quests.getActive();
const inventory = await game.inventory.getItems(character.id);

// Event handling is straightforward
game.on('questComplete', (reward) => {
  console.log('Quest completed! Earned:', reward);
});

// Example game workflow
async function startAdventure() {
  // Mint a new character
  const character = await game.characters.mint();
  
  // Get available quests
  const quests = await game.quests.getActive();
  
  // Start first available quest
  const quest = await game.quests.start(character.id, quests[0].id);
  
  // Listen for completion
  game.on('questComplete', async (data) => {
    const rewards = await game.quests.claimRewards(data.questId);
    console.log('Rewards claimed:', rewards);
  });
}
```

### Error Handling

```typescript
try {
  await game.characters.mint();
} catch (error) {
  if (error.code === 'WALLET_NOT_CONNECTED') {
    // Handle wallet connection error
  } else if (error.code === 'NETWORK_ERROR') {
    // Handle network issues
  } else if (error.code === 'CONTRACT_ERROR') {
    // Handle smart contract errors
  }
}
```

### Testing Guidelines

1. **Unit Testing**
   - Test each service in isolation
   - Mock contract interactions
   - Use TypeScript-native testing frameworks (Jest recommended)

2. **Integration Testing**
   - Test service interactions
   - Use local blockchain for testing (Hardhat/Ganache)
   - Test with real contract deployments

3. **E2E Testing**
   - Test complete workflows
   - Use testnet deployments
   - Validate event handling and state management

### Documentation Requirements

1. **API Documentation**
   - Use TypeDoc for generating API documentation
   - Document all public methods and interfaces
   - Include usage examples

2. **Integration Guide**
   - Step-by-step setup instructions
   - Common usage patterns
   - Error handling best practices

3. **Architecture Documentation**
   - Service interaction diagrams
   - State management flows
   - Event handling patterns

### Performance Considerations

1. **Caching**
   - Implement smart caching for frequently accessed data
   - Cache contract calls where appropriate
   - Use memory cache for active game state

2. **Batch Operations**
   - Support multicall for reading multiple contract states
   - Implement batch transactions where possible
   - Optimize network requests

3. **Event Handling**
   - Efficient event filtering and processing
   - Proper cleanup of event listeners
   - Throttling and debouncing where appropriate 