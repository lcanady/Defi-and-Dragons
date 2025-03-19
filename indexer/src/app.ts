import express, { Request, Response, NextFunction } from 'express';
import dotenv from 'dotenv';
import { DatabaseService } from './services/DatabaseService';
import { CharacterEventHandler } from './handlers/CharacterEventHandler';
import { BlockchainService } from './services/BlockchainService';
import characterRoutes from './api/routes/characters';

// Load environment variables
dotenv.config();

// Create Express app
const app = express();
app.use(express.json());

// Setup routes
app.use('/api/characters', characterRoutes);

// Health check endpoint
app.get('/health', (req: Request, res: Response) => {
  res.json({ status: 'ok' });
});

// Error handling middleware
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something broke!' });
});

// Initialize services
const dbService = new DatabaseService();
const eventHandler = new CharacterEventHandler(dbService);

// Initialize blockchain service if contract address and ABI are provided
if (process.env.CONTRACT_ADDRESS && process.env.CONTRACT_ABI && process.env.RPC_URL) {
  try {
    const contractAbi = JSON.parse(process.env.CONTRACT_ABI);
    const blockchainService = new BlockchainService(
      process.env.CONTRACT_ADDRESS,
      contractAbi,
      eventHandler,
      process.env.RPC_URL
    );
    
    // Start listening to blockchain events
    blockchainService.startListening().catch(console.error);
  } catch (error) {
    console.error('Failed to initialize blockchain service:', error);
  }
}

// Start server
const PORT = process.env.PORT || 3000;
const server = app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

// Handle graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM signal received. Closing server...');
  await dbService.disconnect();
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});

export default app; 