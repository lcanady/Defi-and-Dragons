import { Router, RequestHandler } from 'express';
import { Character } from '../../models/Character';
import { z } from 'zod';
import type { ParamsDictionary } from 'express-serve-static-core';
import type { ParsedQs } from 'qs';

const router = Router();

// Validation schema for query parameters
const querySchema = z.object({
  owner: z.string().optional(),
  class: z.string().optional(),
  minLevel: z.string().transform(Number).optional(),
  maxLevel: z.string().transform(Number).optional(),
});

type QueryParams = z.infer<typeof querySchema>;

// Get all characters with optional filters
const getAllCharacters: RequestHandler = async (req, res) => {
  try {
    const query = querySchema.parse(req.query);
    const filter: Record<string, any> = {};

    if (query.owner) filter.owner = query.owner;
    if (query.class) filter.class = query.class;
    if (query.minLevel) filter['stats.level'] = { $gte: query.minLevel };
    if (query.maxLevel) filter['stats.level'] = { ...filter['stats.level'], $lte: query.maxLevel };

    const characters = await Character.find(filter);
    res.json(characters);
  } catch (error) {
    res.status(400).json({ error: error instanceof Error ? error.message : 'Invalid request' });
  }
};

// Get all characters owned by a specific address
// Note: This route must come before /:tokenId to avoid address being treated as tokenId
const getCharactersByOwner: RequestHandler<{ address: string }> = async (req, res) => {
  try {
    const characters = await Character.find({ owner: req.params.address });
    res.json(characters);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get a specific character by tokenId
const getCharacterByTokenId: RequestHandler<{ tokenId: string }> = async (req, res) => {
  try {
    const character = await Character.findOne({ tokenId: req.params.tokenId });
    if (!character) {
      res.status(404).json({ error: 'Character not found' });
      return;
    }
    res.json(character);
    return;
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
    return;
  }
};

// Register routes
router.get('/', getAllCharacters);
router.get('/owner/:address', getCharactersByOwner);
router.get('/:tokenId', getCharacterByTokenId);

export default router; 