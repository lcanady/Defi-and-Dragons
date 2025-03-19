import mongoose from 'mongoose';
import { Character } from '@/models/Character';
import { CharacterStats } from '@/types';

describe('Character Model', () => {
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

  it('should create new character', async () => {
    const characterData = {
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
    };

    const character = new Character(characterData);
    await character.save();

    const savedCharacter = await Character.findOne({ tokenId: 1 });
    expect(savedCharacter).toBeTruthy();
    expect(savedCharacter?.owner).toBe('0x123');
    expect(savedCharacter?.class).toBe('warrior');
  });

  it('should update character stats', async () => {
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

    const newStats: CharacterStats = {
      strength: 15,
      dexterity: 12,
      constitution: 12,
      intelligence: 8,
      wisdom: 10,
      charisma: 10,
    };

    character.stats = newStats;
    await character.save();

    const updatedCharacter = await Character.findOne({ tokenId: 1 });
    expect(updatedCharacter?.stats.strength).toBe(15);
    expect(updatedCharacter?.stats.dexterity).toBe(12);
  });

  it('should equip/unequip items', async () => {
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

    // Equip item
    const itemId = new mongoose.Types.ObjectId();
    character.equipment.push({
      slot: 'weapon',
      itemId,
      equippedAt: new Date(),
    });

    await character.save();

    // Verify equipment
    let updatedCharacter = await Character.findOne({ tokenId: 1 });
    expect(updatedCharacter?.equipment).toHaveLength(1);
    expect(updatedCharacter?.equipment[0].slot).toBe('weapon');
    expect(updatedCharacter?.equipment[0].itemId).toEqual(itemId);

    // Unequip item
    character.equipment = [];
    await character.save();

    // Verify unequipped
    updatedCharacter = await Character.findOne({ tokenId: 1 });
    expect(updatedCharacter?.equipment).toHaveLength(0);
  });

  it('should track history', async () => {
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

    // Add level up event
    character.history.push({
      action: 'LEVEL_UP',
      timestamp: new Date(),
      details: { level: 2, statsIncreased: ['strength', 'constitution'] },
    });

    await character.save();

    // Add equipment event
    character.history.push({
      action: 'EQUIP_ITEM',
      timestamp: new Date(),
      details: { slot: 'weapon', itemId: new mongoose.Types.ObjectId() },
    });

    await character.save();

    const updatedCharacter = await Character.findOne({ tokenId: 1 });
    expect(updatedCharacter?.history).toHaveLength(2);
    expect(updatedCharacter?.history[0].action).toBe('LEVEL_UP');
    expect(updatedCharacter?.history[1].action).toBe('EQUIP_ITEM');
  });

  it('should validate equipment slots', async () => {
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

    // Try to equip invalid slot
    character.equipment.push({
      slot: 'invalid_slot',
      itemId: new mongoose.Types.ObjectId(),
      equippedAt: new Date(),
    });

    await expect(character.save()).rejects.toThrow();
  });

  it('should prevent duplicate equipment slots', async () => {
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

    // Add first weapon
    character.equipment.push({
      slot: 'weapon',
      itemId: new mongoose.Types.ObjectId(),
      equippedAt: new Date(),
    });

    await character.save();

    // Try to add second weapon
    character.equipment.push({
      slot: 'weapon',
      itemId: new mongoose.Types.ObjectId(),
      equippedAt: new Date(),
    });

    await expect(character.save()).rejects.toThrow('Duplicate equipment slot: weapon');
  });
}); 