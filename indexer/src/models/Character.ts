import mongoose, { Schema, Document } from 'mongoose';
import { CharacterStats } from '@/types';

const VALID_EQUIPMENT_SLOTS = ['weapon', 'armor', 'shield', 'helmet', 'boots', 'accessory'];

export interface ICharacter extends Document {
  tokenId: number;
  owner: string;
  class: string;
  stats: CharacterStats;
  equipment: Array<{
    slot: string;
    itemId: mongoose.Types.ObjectId;
    equippedAt: Date;
  }>;
  history: Array<{
    action: string;
    timestamp: Date;
    details: Record<string, any>;
  }>;
}

const CharacterSchema = new Schema<ICharacter>({
  tokenId: { type: Number, required: true, unique: true },
  owner: { type: String, required: true },
  class: { type: String, required: true },
  stats: {
    strength: { type: Number, required: true },
    dexterity: { type: Number, required: true },
    constitution: { type: Number, required: true },
    intelligence: { type: Number, required: true },
    wisdom: { type: Number, required: true },
    charisma: { type: Number, required: true },
  },
  equipment: [{
    slot: { 
      type: String, 
      required: true,
      enum: VALID_EQUIPMENT_SLOTS,
      message: `Slot must be one of: ${VALID_EQUIPMENT_SLOTS.join(', ')}`
    },
    itemId: { type: Schema.Types.ObjectId, required: true },
    equippedAt: { type: Date, default: Date.now },
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
CharacterSchema.index({ owner: 1 });

// Ensure only one item per slot
CharacterSchema.pre('save', function(next) {
  const slots = new Set();
  for (const item of this.equipment) {
    if (slots.has(item.slot)) {
      next(new Error(`Duplicate equipment slot: ${item.slot}`));
      return;
    }
    slots.add(item.slot);
  }
  next();
});

export const Character = mongoose.model<ICharacter>('Character', CharacterSchema); 