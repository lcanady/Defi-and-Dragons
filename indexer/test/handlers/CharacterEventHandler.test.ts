import { CharacterEventHandler } from '../../src/handlers/CharacterEventHandler';
import { DatabaseService } from '../../src/services/DatabaseService';
import { CharacterEvent, CharacterStats } from '../../src/types';

// Mock DatabaseService
jest.mock('@/services/DatabaseService');

describe('CharacterEventHandler', () => {
  let handler: CharacterEventHandler;
  let dbService: jest.Mocked<DatabaseService>;

  beforeEach(() => {
    jest.clearAllMocks();
    dbService = new DatabaseService() as jest.Mocked<DatabaseService>;
    handler = new CharacterEventHandler(dbService);
  });

  describe('handleCreated', () => {
    it('should handle character creation', async () => {
      const stats: CharacterStats = {
        strength: 10,
        dexterity: 10,
        constitution: 10,
        intelligence: 10,
        wisdom: 10,
        charisma: 10
      };

      const event: CharacterEvent = {
        type: 'CHARACTER_CREATED',
        tokenId: 1,
        owner: '0x123',
        timestamp: Math.floor(Date.now() / 1000),
        data: {
          tokenId: '1',
          owner: '0x123',
          stats
        }
      };

      await handler.handleEvent(event);

      expect(dbService.updateCharacter).toHaveBeenCalledWith(event.tokenId, event.data);
    });

    it('should handle failed character creation', async () => {
      const stats: CharacterStats = {
        strength: 10,
        dexterity: 10,
        constitution: 10,
        intelligence: 10,
        wisdom: 10,
        charisma: 10
      };

      const event: CharacterEvent = {
        type: 'CHARACTER_CREATED',
        tokenId: 1,
        owner: '0x123',
        timestamp: Math.floor(Date.now() / 1000),
        data: {
          tokenId: '1',
          owner: '0x123',
          stats
        }
      };

      (dbService.updateCharacter as jest.Mock).mockRejectedValueOnce(new Error('Database error'));

      await expect(handler.handleEvent(event)).rejects.toThrow('Database error');
    });
  });

  describe('handleUpdated', () => {
    it('should handle character update', async () => {
      const stats: CharacterStats = {
        strength: 12,
        dexterity: 12,
        constitution: 12,
        intelligence: 12,
        wisdom: 12,
        charisma: 12
      };

      const event: CharacterEvent = {
        type: 'CHARACTER_UPDATED',
        tokenId: 1,
        owner: '0x123',
        timestamp: Math.floor(Date.now() / 1000),
        data: {
          tokenId: '1',
          owner: '0x123',
          stats
        }
      };

      await handler.handleEvent(event);

      expect(dbService.updateCharacter).toHaveBeenCalledWith(event.tokenId, event.data);
    });

    it('should handle failed character update', async () => {
      const stats: CharacterStats = {
        strength: 12,
        dexterity: 12,
        constitution: 12,
        intelligence: 12,
        wisdom: 12,
        charisma: 12
      };

      const event: CharacterEvent = {
        type: 'CHARACTER_UPDATED',
        tokenId: 1,
        owner: '0x123',
        timestamp: Math.floor(Date.now() / 1000),
        data: {
          tokenId: '1',
          owner: '0x123',
          stats
        }
      };

      (dbService.updateCharacter as jest.Mock).mockRejectedValueOnce(new Error('Database error'));

      await expect(handler.handleEvent(event)).rejects.toThrow('Database error');
    });
  });

  describe('handleDeleted', () => {
    it('should handle character deletion', async () => {
      const event: CharacterEvent = {
        type: 'CHARACTER_DELETED',
        tokenId: 1,
        owner: '0x123',
        timestamp: Math.floor(Date.now() / 1000)
      };

      await handler.handleEvent(event);

      expect(dbService.deleteCharacter).toHaveBeenCalledWith(event.tokenId);
    });
  });

  describe('handleLevelUp', () => {
    it('should handle character level up', async () => {
      const existingCharacter = {
        tokenId: '1',
        owner: '0x123',
        stats: {
          strength: 10,
          dexterity: 10,
          constitution: 10,
          intelligence: 10,
          wisdom: 10,
          charisma: 10
        }
      };

      const updatedStats = {
        strength: 12,
        dexterity: 12,
        constitution: 12,
        intelligence: 12,
        wisdom: 12,
        charisma: 12
      };

      const event: CharacterEvent = {
        type: 'CHARACTER_LEVEL_UP',
        tokenId: 1,
        owner: '0x123',
        timestamp: Math.floor(Date.now() / 1000),
        level: 2,
        data: {
          tokenId: '1',
          owner: '0x123',
          stats: updatedStats
        }
      };

      (dbService.getCharacter as jest.Mock).mockResolvedValueOnce(existingCharacter);

      await handler.handleEvent(event);

      expect(dbService.getCharacter).toHaveBeenCalledWith(event.tokenId);
      expect(dbService.updateCharacter).toHaveBeenCalledWith(event.tokenId, event.data);
    });

    it('should handle level up for non-existent character', async () => {
      const updatedStats = {
        strength: 12,
        dexterity: 12,
        constitution: 12,
        intelligence: 12,
        wisdom: 12,
        charisma: 12
      };

      const event: CharacterEvent = {
        type: 'CHARACTER_LEVEL_UP',
        tokenId: 1,
        owner: '0x123',
        timestamp: Math.floor(Date.now() / 1000),
        level: 2,
        data: {
          tokenId: '1',
          owner: '0x123',
          stats: updatedStats
        }
      };

      (dbService.getCharacter as jest.Mock).mockResolvedValueOnce(null);

      await expect(handler.handleEvent(event)).rejects.toThrow('Character not found');
    });
  });

  describe('handleTransfer', () => {
    it('should handle character transfer', async () => {
      const event: CharacterEvent = {
        type: 'CHARACTER_TRANSFER',
        tokenId: 1,
        owner: '0x123',
        newOwner: '0x456',
        timestamp: Math.floor(Date.now() / 1000),
        data: {
          tokenId: '1',
          owner: '0x456'
        }
      };

      await handler.handleEvent(event);

      expect(dbService.updateCharacter).toHaveBeenCalledWith(event.tokenId, event.data);
    });

    it('should handle failed character transfer', async () => {
      const event: CharacterEvent = {
        type: 'CHARACTER_TRANSFER',
        tokenId: 1,
        owner: '0x123',
        newOwner: '0x456',
        timestamp: Math.floor(Date.now() / 1000),
        data: {
          tokenId: '1',
          owner: '0x456'
        }
      };

      (dbService.updateCharacter as jest.Mock).mockRejectedValueOnce(new Error('Database error'));

      await expect(handler.handleEvent(event)).rejects.toThrow('Database error');
    });
  });
}); 