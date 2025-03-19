import { QuestEventHandler } from '@/handlers/QuestEventHandler';
import { DatabaseService } from '@/services/DatabaseService';
import { QuestEvent } from '@/types';

// Mock DatabaseService
jest.mock('@/services/DatabaseService');

describe('Quest Event Handler', () => {
  let handler: QuestEventHandler;
  let dbService: jest.Mocked<DatabaseService>;

  beforeEach(() => {
    dbService = new DatabaseService() as jest.Mocked<DatabaseService>;
    handler = new QuestEventHandler(dbService);
  });

  it('should handle quest creation', async () => {
    const event: QuestEvent = {
      type: 'QUEST_CREATED',
      questId: 1,
      name: 'Test Quest',
      rewards: [{ type: 'XP', amount: 100 }],
      timestamp: Date.now(),
    };

    await handler.handleCreated(event);
    expect(dbService.createQuest).toHaveBeenCalledWith(expect.objectContaining({
      questId: 1,
      name: 'Test Quest',
    }));
  });

  it('should process participant joins', async () => {
    const event: QuestEvent = {
      type: 'QUEST_JOINED',
      questId: 1,
      characterId: 1,
      timestamp: Date.now(),
    };

    await handler.handleJoined(event);
    expect(dbService.addQuestParticipant).toHaveBeenCalledWith(1, 1);
  });

  it('should track quest progress', async () => {
    const event: QuestEvent = {
      type: 'QUEST_PROGRESS',
      questId: 1,
      progress: 50,
      timestamp: Date.now(),
    };

    await handler.handleProgress(event);
    expect(dbService.updateQuestProgress).toHaveBeenCalledWith(1, 50);
  });

  it('should handle quest completion', async () => {
    const event: QuestEvent = {
      type: 'QUEST_COMPLETED',
      questId: 1,
      completedBy: [1, 2],
      timestamp: Date.now(),
    };

    await handler.handleCompleted(event);
    expect(dbService.completeQuest).toHaveBeenCalledWith(1, expect.any(Array));
  });

  it('should process reward distribution', async () => {
    const event: QuestEvent = {
      type: 'QUEST_REWARDS_DISTRIBUTED',
      questId: 1,
      rewards: [
        { characterId: 1, type: 'XP', amount: 100 },
        { characterId: 2, type: 'XP', amount: 100 },
      ],
      timestamp: Date.now(),
    };

    await handler.handleRewardsDistributed(event);
    expect(dbService.distributeQuestRewards).toHaveBeenCalledWith(1, expect.any(Array));
  });
}); 