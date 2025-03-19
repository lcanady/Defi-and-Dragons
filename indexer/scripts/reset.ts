import mongoose from 'mongoose';
import config from '../src/config';
import { Character } from '../src/models/Character';

async function reset(): Promise<void> {
  try {
    await mongoose.connect(config.db.uri);
    console.log('Connected to database');

    // Drop all collections
    console.log('Dropping collections...');
    const collections = await (mongoose.connection.db!).collections();
    for (const collection of collections) {
      await collection.drop();
    }
    console.log('Collections dropped');

    // Recreate indexes
    console.log('Recreating indexes...');
    await Promise.all([
      Character.collection.createIndex({ tokenId: 1 }, { unique: true }),
      Character.collection.createIndex({ owner: 1 }),
      Character.collection.createIndex({ class: 1 }),
    ]);
    console.log('Indexes recreated');

    console.log('Database reset completed successfully');
  } catch (error) {
    console.error('Database reset failed:', error);
    process.exit(1);
  } finally {
    await mongoose.disconnect();
  }
}

reset().catch(console.error); 