import mongoose from 'mongoose';
import { Character } from '@/models/Character';

describe('Character Schema', () => {
  beforeAll(async () => {
    if (!mongoose.connection.readyState) {
      await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/test');
    }
  });

  afterAll(async () => {
    await mongoose.disconnect();
  });

  beforeEach(async () => {
    await mongoose.connection.dropDatabase();
  });

  it('should validate required fields', async () => {
    const invalidCharacter = new Character({
      // Missing required fields
    });

    await expect(invalidCharacter.validate()).rejects.toThrow();
  });

  it('should enforce field types', async () => {
    const invalidCharacter = new Character({
      tokenId: 'not-a-number', // Should be number
      owner: 123, // Should be string
      class: 123, // Should be string
      stats: {
        strength: 'not-a-number', // Should be number
        dexterity: 'not-a-number',
        constitution: 'not-a-number',
        intelligence: 'not-a-number',
        wisdom: 'not-a-number',
        charisma: 'not-a-number',
      },
    });

    await expect(invalidCharacter.validate()).rejects.toThrow();
  });

  it('should handle equipment updates atomically', async () => {
    const character = new Character({
      tokenId: 1,
      owner: '0x123',
      class: 'warrior',
      stats: {
        strength: 10,
        dexterity: 10,
        constitution: 10,
        intelligence: 10,
        wisdom: 10,
        charisma: 10,
      },
    });

    await character.save();

    // Add equipment
    character.equipment.push({
      slot: 'weapon',
      itemId: new mongoose.Types.ObjectId(),
      equippedAt: new Date(),
    });

    await character.save();
    const updated = await Character.findOne({ tokenId: 1 });
    expect(updated?.equipment).toHaveLength(1);
  });

  it('should maintain history correctly', async () => {
    const character = new Character({
      tokenId: 1,
      owner: '0x123',
      class: 'warrior',
      stats: {
        strength: 10,
        dexterity: 10,
        constitution: 10,
        intelligence: 10,
        wisdom: 10,
        charisma: 10,
      },
    });

    await character.save();

    // Add history entry
    character.history.push({
      action: 'LEVEL_UP',
      timestamp: new Date(),
      details: { level: 2 },
    });

    await character.save();
    const updated = await Character.findOne({ tokenId: 1 });
    expect(updated?.history).toHaveLength(1);
    expect(updated?.history[0].action).toBe('LEVEL_UP');
  });
}); 