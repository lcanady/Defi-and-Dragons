import mongoose from 'mongoose';
import { Character } from '@/models/Character';
import { Quest } from '@/models/Quest';
import { CharacterStats } from '@/types';

export class DatabaseService {
  private maxRetries = 3;
  private retryDelay = 1000;

  async connect(uri: string): Promise<void> {
    let retries = 0;
    while (retries < this.maxRetries) {
      try {
        await mongoose.connect(uri, {
          maxPoolSize: 10,
          serverSelectionTimeoutMS: 5000,
          socketTimeoutMS: 45000,
        });
        console.log('Connected to MongoDB');
        this.setupConnectionHandlers();
        return;
      } catch (error) {
        retries++;
        if (retries === this.maxRetries) {
          throw error;
        }
        await new Promise(resolve => setTimeout(resolve, this.retryDelay));
      }
    }
  }

  private setupConnectionHandlers(): void {
    mongoose.connection.on('error', (error) => {
      console.error('MongoDB connection error:', error);
    });

    mongoose.connection.on('disconnected', () => {
      console.log('MongoDB disconnected');
    });

    mongoose.connection.on('reconnected', () => {
      console.log('MongoDB reconnected');
    });
  }

  async disconnect(): Promise<void> {
    try {
      await mongoose.disconnect();
      console.log('Disconnected from MongoDB');
    } catch (error) {
      console.error('Error disconnecting from MongoDB:', error);
      throw error;
    }
  }

  // Character operations
  async createCharacter(data: {
    tokenId: number;
    owner: string;
    class: string;
    stats: CharacterStats;
  }): Promise<any> {
    const character = new Character(data);
    return character.save();
  }

  async getCharacter(tokenId: number): Promise<any> {
    try {
      return await Character.findOne({ tokenId });
    } catch (error) {
      console.error('Error getting character:', error);
      throw error;
    }
  }

  async updateCharacter(tokenId: number, updates: Partial<any>): Promise<any> {
    return Character.findOneAndUpdate({ tokenId }, updates, { new: true });
  }

  async deleteCharacter(tokenId: number): Promise<boolean> {
    const result = await Character.deleteOne({ tokenId });
    return result.deletedCount === 1;
  }

  // Quest operations
  async createQuest(data: {
    questId: number;
    name: string;
    rewards: Array<{ type: string; amount: number }>;
  }): Promise<any> {
    const quest = new Quest(data);
    return quest.save();
  }

  async addQuestParticipant(questId: number, characterId: number): Promise<any> {
    return Quest.findOneAndUpdate(
      { questId },
      {
        $push: {
          participants: {
            characterId,
            joinedAt: new Date(),
            status: 'ACTIVE',
          },
        },
      },
      { new: true }
    );
  }

  async updateQuestProgress(questId: number, progress: number): Promise<any> {
    return Quest.findOneAndUpdate(
      { questId },
      { progress },
      { new: true }
    );
  }

  async completeQuest(questId: number, completedBy: number[]): Promise<any> {
    return Quest.findOneAndUpdate(
      { questId },
      {
        status: 'COMPLETED',
        'participants.$[elem].status': 'COMPLETED',
      },
      {
        arrayFilters: [{ 'elem.characterId': { $in: completedBy } }],
        new: true,
      }
    );
  }

  async distributeQuestRewards(questId: number, rewards: Array<{
    characterId: number;
    type: string;
    amount: number;
  }>): Promise<any> {
    const quest = await Quest.findOne({ questId });
    if (!quest) throw new Error('Quest not found');

    // Update quest rewards distribution
    quest.rewards = rewards.map(reward => ({
      ...reward,
      distributedAt: new Date(),
    }));

    return quest.save();
  }
} 