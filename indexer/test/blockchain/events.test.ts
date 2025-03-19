import { JsonRpcProvider, Block, Contract } from 'ethers';
import { BlockchainService } from '../../src/services/BlockchainService';
import { CharacterEventHandler } from '../../src/handlers/CharacterEventHandler';
import { DatabaseService } from '../../src/services/DatabaseService';

// Mock all external dependencies
jest.mock('../../src/services/DatabaseService');
jest.mock('../../src/handlers/CharacterEventHandler');

// Mock ethers completely
jest.mock('ethers', () => {
  const mockProvider = {
    getBlock: jest.fn(),
    getNetwork: jest.fn().mockResolvedValue({ chainId: 1n }),
    on: jest.fn(),
    removeListener: jest.fn(),
    removeAllListeners: jest.fn()
  };

  const mockContract = {
    on: jest.fn(),
    removeAllListeners: jest.fn(),
    ownerOf: jest.fn()
  };

  return {
    JsonRpcProvider: jest.fn(() => mockProvider),
    Contract: jest.fn(() => mockContract),
    ethers: {
      JsonRpcProvider: jest.fn(() => mockProvider),
      Contract: jest.fn(() => mockContract)
    }
  };
});

describe('Event Listener', () => {
  let blockchainService: BlockchainService;
  let mockProvider: jest.Mocked<JsonRpcProvider>;
  let characterEventHandler: jest.Mocked<CharacterEventHandler>;
  let databaseService: jest.Mocked<DatabaseService>;

  beforeEach(() => {
    jest.clearAllMocks();

    // Get the mocked instances
    const { ethers } = require('ethers');
    mockProvider = new ethers.JsonRpcProvider() as jest.Mocked<JsonRpcProvider>;
    databaseService = new DatabaseService() as jest.Mocked<DatabaseService>;
    characterEventHandler = new CharacterEventHandler(databaseService) as jest.Mocked<CharacterEventHandler>;

    mockProvider.getBlock.mockImplementation((blockNumber) => 
      Promise.resolve({
        hash: `0x${blockNumber}`,
        parentHash: `0x${Number(blockNumber) - 1}`,
        number: Number(blockNumber),
        timestamp: Math.floor(Date.now() / 1000),
        _difficulty: BigInt(0)
      } as unknown as Block)
    );

    blockchainService = new BlockchainService(
      'mock-contract-address',
      [],
      characterEventHandler,
      'mock-rpc-url',
      1,
      0
    );
  });

  it('should process new blocks', async () => {
    await blockchainService.connect();
    const blockHandler = mockProvider.on.mock.calls.find(call => call[0] === 'block')?.[1];
    expect(blockHandler).toBeDefined();
    
    if (blockHandler) {
      await blockHandler(100);
      expect(mockProvider.getBlock).toHaveBeenCalledWith(100);
    }
  });

  it('should handle reorgs', async () => {
    await blockchainService.connect();
    const blockHandler = mockProvider.on.mock.calls.find(call => call[0] === 'block')?.[1];
    expect(blockHandler).toBeDefined();

    // Clear previous mock calls
    mockProvider.getBlock.mockClear();

    // Mock both the block and its parent for each call
    mockProvider.getBlock
      // First block check
      .mockResolvedValueOnce({
        hash: '0x100',
        parentHash: '0x99',
        number: 100,
        timestamp: Math.floor(Date.now() / 1000),
        _difficulty: BigInt(0)
      } as unknown as Block)
      // First parent check
      .mockResolvedValueOnce({
        hash: '0x99',
        parentHash: '0x98',
        number: 99,
        timestamp: Math.floor(Date.now() / 1000),
        _difficulty: BigInt(0)
      } as unknown as Block)
      // Second block check
      .mockResolvedValueOnce({
        hash: '0x100-new',
        parentHash: '0x99-new',
        number: 100,
        timestamp: Math.floor(Date.now() / 1000),
        _difficulty: BigInt(0)
      } as unknown as Block)
      // Second parent check
      .mockResolvedValueOnce({
        hash: '0x99-different',
        parentHash: '0x98',
        number: 99,
        timestamp: Math.floor(Date.now() / 1000),
        _difficulty: BigInt(0)
      } as unknown as Block);

    if (blockHandler) {
      await blockHandler(100);
      await blockHandler(100);
      expect(mockProvider.getBlock).toHaveBeenCalledTimes(4);
    }
  });

  it('should handle provider errors', async () => {
    await blockchainService.connect();
    const blockHandler = mockProvider.on.mock.calls.find(call => call[0] === 'block')?.[1];
    expect(blockHandler).toBeDefined();

    // Clear previous mock calls
    mockProvider.getBlock.mockClear();
    
    // Mock the error
    mockProvider.getBlock.mockRejectedValueOnce(new Error('Provider error'));
    
    // Create a spy to verify the error was logged
    const consoleErrorSpy = jest.spyOn(console, 'error');
    
    if (blockHandler) {
      await blockHandler(100);
      expect(consoleErrorSpy).toHaveBeenCalledWith('Error processing block:', expect.any(Error));
    }

    consoleErrorSpy.mockRestore();
  });

  afterEach(() => {
    jest.clearAllMocks();
  });
}); 