import mongoose from 'mongoose';
import config from '../src/config';
import { Character } from '../src/models/Character';

const mockCharacters = [
  {
    tokenId: 1,
    owner: '0x1234567890123456789012345678901234567890',
    class: 'Warrior',
    stats: {
      strength: 15,
      dexterity: 12,
      constitution: 14,
      intelligence: 8,
      wisdom: 10,
      charisma: 13,
    },
  },
  {
    tokenId: 2,
    owner: '0x2345678901234567890123456789012345678901',
    class: 'Mage',
    stats: {
      strength: 8,
      dexterity: 10,
      constitution: 12,
      intelligence: 15,
      wisdom: 14,
      charisma: 12,
    },
  },
  {
    tokenId: 3,
    owner: '0x3456789012345678901234567890123456789012',
    class: 'Rogue',
    stats: {
      strength: 12,
      dexterity: 15,
      constitution: 10,
      intelligence: 13,
      wisdom: 8,
      charisma: 14,
    },
  },
];

async function seed(): Promise<void> {
  try {
    await mongoose.connect(config.db.uri);
    console.log('Connected to database');

    // Clear existing data
    await Character.deleteMany({});
    console.log('Cleared existing characters');

    // Insert mock data
    await Character.insertMany(mockCharacters);
    console.log('Inserted mock characters');

    console.log('Seeding completed successfully');
  } catch (error) {
    console.error('Seeding failed:', error);
    process.exit(1);
  } finally {
    await mongoose.disconnect();
  }
}

seed().catch(console.error); 