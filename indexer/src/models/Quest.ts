import mongoose, { Schema, Document } from 'mongoose';

export interface IQuest extends Document {
  questId: number;
  name: string;
  status: 'ACTIVE' | 'COMPLETED' | 'FAILED';
  participants: Array<{
    characterId: number;
    joinedAt: Date;
    status: 'ACTIVE' | 'COMPLETED' | 'FAILED';
  }>;
  progress: number;
  rewards: Array<{
    characterId?: number;
    type: string;
    amount: number;
    distributedAt?: Date;
  }>;
  history: Array<{
    action: string;
    timestamp: Date;
    details: Record<string, any>;
  }>;
}

const QuestSchema = new Schema<IQuest>({
  questId: { type: Number, required: true, unique: true },
  name: { type: String, required: true },
  status: {
    type: String,
    enum: ['ACTIVE', 'COMPLETED', 'FAILED'],
    default: 'ACTIVE',
  },
  participants: [{
    characterId: { type: Number, required: true },
    joinedAt: { type: Date, default: Date.now },
    status: {
      type: String,
      enum: ['ACTIVE', 'COMPLETED', 'FAILED'],
      default: 'ACTIVE',
    },
  }],
  progress: {
    type: Number,
    default: 0,
    min: 0,
    max: 100,
  },
  rewards: [{
    characterId: { type: Number },
    type: { type: String, required: true },
    amount: { type: Number, required: true },
    distributedAt: { type: Date },
  }],
  history: [{
    action: { type: String, required: true },
    timestamp: { type: Date, default: Date.now },
    details: { type: Schema.Types.Mixed },
  }],
}, {
  timestamps: true,
});

// Indexes
QuestSchema.index({ status: 1 });
QuestSchema.index({ 'participants.characterId': 1 });

export const Quest = mongoose.model<IQuest>('Quest', QuestSchema); 