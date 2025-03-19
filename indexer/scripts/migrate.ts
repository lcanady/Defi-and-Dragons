import mongoose from 'mongoose';
import config from '../src/config';
import { Character } from '../src/models/Character';

async function migrate(): Promise<void> {
  try {
    await mongoose.connect(config.db.uri);
    console.log('Connected to database');

    // Create indexes
    console.log('Creating indexes...');
    await Promise.all([
      Character.collection.createIndex({ tokenId: 1 }, { unique: true }),
      Character.collection.createIndex({ owner: 1 }),
      Character.collection.createIndex({ class: 1 }),
    ]);

    console.log('Migration completed successfully');
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  } finally {
    await mongoose.disconnect();
  }
}

migrate().catch(console.error); 