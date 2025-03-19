export interface CharacterStats {
  strength: number;
  dexterity: number;
  constitution: number;
  intelligence: number;
  wisdom: number;
  charisma: number;
}

export interface CharacterData {
  tokenId: string;
  owner?: string;
  name?: string;
  class?: string;
  stats?: CharacterStats;
}

export interface CharacterEvent {
  type: 'CHARACTER_CREATED' | 'CHARACTER_UPDATED' | 'CHARACTER_DELETED' | 'CHARACTER_LEVEL_UP' | 'CHARACTER_TRANSFER';
  tokenId: number;
  owner: string;
  timestamp: number;
  stats?: CharacterStats;
  newOwner?: string;
  level?: number;
  data?: any;
}

export interface QuestEvent {
  type: 'QUEST_CREATED' | 'QUEST_JOINED' | 'QUEST_PROGRESS' | 'QUEST_COMPLETED' | 'QUEST_REWARDS_DISTRIBUTED';
  questId: number;
  timestamp: number;
  name?: string;
  rewards?: Array<{
    type: string;
    amount: number;
    characterId?: number;
  }>;
  characterId?: number;
  progress?: number;
  completedBy?: number[];
}

export interface Character {
  tokenId: string;
  owner?: string;
  name?: string;
  class?: string;
  stats?: CharacterStats;
  createdAt?: Date;
  updatedAt?: Date;
} 