import { DatabaseService } from '@/services/DatabaseService';
import { QuestEvent } from '@/types';

export class QuestEventHandler {
  constructor(private dbService: DatabaseService) {}

  async handleCreated(event: QuestEvent): Promise<void> {
    if (!event.name || !event.rewards) {
      throw new Error('Missing required data for quest creation');
    }

    await this.dbService.createQuest({
      questId: event.questId,
      name: event.name,
      rewards: event.rewards,
    });
  }

  async handleJoined(event: QuestEvent): Promise<void> {
    if (!event.characterId) {
      throw new Error('Missing character ID for quest join');
    }

    await this.dbService.addQuestParticipant(event.questId, event.characterId);
  }

  async handleProgress(event: QuestEvent): Promise<void> {
    if (event.progress === undefined) {
      throw new Error('Missing progress data');
    }

    await this.dbService.updateQuestProgress(event.questId, event.progress);
  }

  async handleCompleted(event: QuestEvent): Promise<void> {
    if (!event.completedBy) {
      throw new Error('Missing completion data');
    }

    await this.dbService.completeQuest(event.questId, event.completedBy);
  }

  async handleRewardsDistributed(event: QuestEvent): Promise<void> {
    if (!event.rewards) {
      throw new Error('Missing rewards data');
    }

    // Transform rewards to match the expected type
    const transformedRewards = event.rewards.map(reward => {
      if (!reward.characterId) {
        throw new Error('Missing characterId in reward data');
      }
      return {
        characterId: reward.characterId,
        type: reward.type,
        amount: reward.amount
      };
    });

    await this.dbService.distributeQuestRewards(event.questId, transformedRewards);
  }
} 