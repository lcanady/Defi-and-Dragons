import { DatabaseService } from '../services/DatabaseService';
import { CharacterEvent } from '../types';

export class CharacterEventHandler {
  constructor(private dbService: DatabaseService) {}

  async handleEvent(event: CharacterEvent): Promise<void> {
    switch (event.type) {
      case 'CHARACTER_CREATED':
        await this.handleCreated(event);
        break;
      case 'CHARACTER_UPDATED':
        await this.handleUpdated(event);
        break;
      case 'CHARACTER_DELETED':
        await this.handleDeleted(event);
        break;
      case 'CHARACTER_LEVEL_UP':
        await this.handleLevelUp(event);
        break;
      case 'CHARACTER_TRANSFER':
        await this.handleTransfer(event);
        break;
      default:
        throw new Error(`Unknown event type: ${event.type}`);
    }
  }

  private async handleCreated(event: CharacterEvent): Promise<void> {
    if (!event.data) {
      throw new Error('Missing character data');
    }
    await this.dbService.updateCharacter(event.tokenId, event.data);
  }

  private async handleUpdated(event: CharacterEvent): Promise<void> {
    if (!event.data) {
      throw new Error('Missing character data');
    }
    await this.dbService.updateCharacter(event.tokenId, event.data);
  }

  private async handleDeleted(event: CharacterEvent): Promise<void> {
    await this.dbService.deleteCharacter(event.tokenId);
  }

  private async handleLevelUp(event: CharacterEvent): Promise<void> {
    if (!event.data) {
      throw new Error('Missing character data');
    }

    const character = await this.dbService.getCharacter(event.tokenId);
    if (!character) {
      throw new Error('Character not found');
    }

    await this.dbService.updateCharacter(event.tokenId, event.data);
  }

  private async handleTransfer(event: CharacterEvent): Promise<void> {
    if (!event.data) {
      throw new Error('Missing character data');
    }
    await this.dbService.updateCharacter(event.tokenId, event.data);
  }
} 