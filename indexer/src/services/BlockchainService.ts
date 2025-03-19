import { ethers } from 'ethers';
import { CharacterEventHandler } from '../handlers/CharacterEventHandler';
import { CharacterEvent, CharacterStats, CharacterData } from '../types';

type BlockHandler = (blockNumber: number) => Promise<void>;
type ReorgHandler = (blockNumber: number) => Promise<void>;

export class BlockchainService {
  private provider: ethers.JsonRpcProvider;
  private contract: ethers.Contract;
  private blockHandlers: BlockHandler[];
  private reorgHandlers: ReorgHandler[];
  private isConnected: boolean;
  private reconnectAttempts: number;
  private maxReconnectAttempts: number;
  private reconnectDelay: number;

  constructor(
    private contractAddress: string,
    private contractAbi: any[],
    private eventHandler: CharacterEventHandler,
    rpcUrl: string,
    maxReconnectAttempts = 5,
    reconnectDelay = 1000
  ) {
    this.provider = new ethers.JsonRpcProvider(rpcUrl);
    this.contract = new ethers.Contract(contractAddress, contractAbi, this.provider);
    this.blockHandlers = [];
    this.reorgHandlers = [];
    this.isConnected = false;
    this.reconnectAttempts = 0;
    this.maxReconnectAttempts = maxReconnectAttempts;
    this.reconnectDelay = reconnectDelay;
  }

  public async connect(): Promise<void> {
    try {
      await this.provider.getNetwork();
      this.isConnected = true;
      this.reconnectAttempts = 0;
      this.setupEventListeners();
    } catch (error) {
      console.error('Failed to connect:', error);
      await this.handleDisconnect();
    }
  }

  private setupEventListeners(): void {
    if ('_websocket' in this.provider) {
      const wsProvider = this.provider as unknown as { _websocket: { on: (event: string, handler: () => void) => void } };
      wsProvider._websocket.on('close', () => {
        console.log('WebSocket connection closed');
        this.handleDisconnect();
      });
    }

    this.provider.on('block', async (blockNumber: number) => {
      await this.processBlock(blockNumber);
    });

    this.provider.on('error', async () => {
      await this.handleDisconnect();
    });

    // Character Created event
    this.contract.on('CharacterCreated', async (tokenId: string, owner: string, name: string, characterClass: string, stats: CharacterStats) => {
      const event: CharacterEvent = {
        type: 'CHARACTER_CREATED',
        tokenId: parseInt(tokenId, 10),
        owner,
        timestamp: Math.floor(Date.now() / 1000),
        data: {
          tokenId,
          owner,
          name,
          class: characterClass,
          stats,
        }
      };
      await this.eventHandler.handleEvent(event);
    });

    // Character Updated event
    this.contract.on('CharacterUpdated', async (tokenId: string, stats: CharacterStats) => {
      const event: CharacterEvent = {
        type: 'CHARACTER_UPDATED',
        tokenId: parseInt(tokenId, 10),
        owner: await this.contract.ownerOf(tokenId),
        timestamp: Math.floor(Date.now() / 1000),
        data: {
          tokenId,
          stats,
        }
      };
      await this.eventHandler.handleEvent(event);
    });

    // Character Level Up event
    this.contract.on('CharacterLevelUp', async (tokenId: string, stats: CharacterStats) => {
      const event: CharacterEvent = {
        type: 'CHARACTER_LEVEL_UP',
        tokenId: parseInt(tokenId, 10),
        owner: await this.contract.ownerOf(tokenId),
        timestamp: Math.floor(Date.now() / 1000),
        data: {
          tokenId,
          stats,
        }
      };
      await this.eventHandler.handleEvent(event);
    });

    // Character Transfer event
    this.contract.on('Transfer', async (from: string, to: string, tokenId: string) => {
      const event: CharacterEvent = {
        type: 'CHARACTER_TRANSFER',
        tokenId: parseInt(tokenId, 10),
        owner: from,
        newOwner: to,
        timestamp: Math.floor(Date.now() / 1000),
        data: {
          tokenId,
          owner: to,
        }
      };
      await this.eventHandler.handleEvent(event);
    });
  }

  private async handleDisconnect(): Promise<void> {
    this.isConnected = false;
    if (this.reconnectAttempts < this.maxReconnectAttempts) {
      this.reconnectAttempts++;
      console.log(`Attempting to reconnect (${this.reconnectAttempts}/${this.maxReconnectAttempts})...`);
      await new Promise(resolve => setTimeout(resolve, this.reconnectDelay));
      await this.connect();
    } else {
      console.error('Max reconnection attempts reached');
    }
  }

  private async processBlock(blockNumber: number): Promise<void> {
    try {
      const block = await this.provider.getBlock(blockNumber);
      if (!block) return;

      if (block.parentHash !== (await this.provider.getBlock(blockNumber - 1))?.hash) {
        await this.handleReorg(blockNumber);
        return;
      }

      for (const handler of this.blockHandlers) {
        await handler(blockNumber);
      }
    } catch (error) {
      console.error('Error processing block:', error);
    }
  }

  private async handleReorg(blockNumber: number): Promise<void> {
    for (const handler of this.reorgHandlers) {
      await handler(blockNumber);
    }
  }

  public onBlock(handler: BlockHandler): void {
    this.blockHandlers.push(handler);
  }

  public onReorg(handler: ReorgHandler): void {
    this.reorgHandlers.push(handler);
  }

  public removeBlockHandler(handler: BlockHandler): void {
    this.blockHandlers = this.blockHandlers.filter(h => h !== handler);
  }

  public removeReorgHandler(handler: ReorgHandler): void {
    this.reorgHandlers = this.reorgHandlers.filter(h => h !== handler);
  }

  public async disconnect(): Promise<void> {
    this.provider.removeAllListeners();
    this.isConnected = false;
  }

  public isConnectionActive(): boolean {
    return this.isConnected;
  }

  async startListening(): Promise<void> {
    console.log('Started listening to blockchain events');
  }

  async stopListening(): Promise<void> {
    this.contract.removeAllListeners();
    console.log('Stopped listening to blockchain events');
  }
} 