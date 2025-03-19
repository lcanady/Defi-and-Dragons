# DnD Character Indexer

This service indexes DnD character NFTs from the blockchain and stores their data in MongoDB for efficient querying.

## Prerequisites

- Node.js (v16 or higher)
- Docker and Docker Compose
- MongoDB (provided via Docker)
- Ganache (provided via Docker)

## Setup

1. Install dependencies:
```bash
npm install
```

2. Create a `.env` file in the root directory with the following variables:
```env
MONGODB_URI=mongodb://root:example@localhost:27017/dnd?authSource=admin
RPC_URL=http://localhost:8545
CONTRACT_ADDRESS=your_contract_address_here
```

3. Start the local development environment:
```bash
npm run docker:up
```

This will start:
- MongoDB on port 27017
- Mongo Express (web UI) on port 8081
- Ganache on port 8545

## Available Commands

### Development
- `npm run dev` - Start the service in development mode with hot reloading
- `npm start` - Start the service in production mode
- `npm run build` - Build the TypeScript code
- `npm run type-check` - Check TypeScript types

### Testing
- `npm test` - Run tests
- `npm run test:watch` - Run tests in watch mode
- `npm run test:coverage` - Run tests with coverage report

### Code Quality
- `npm run lint` - Run ESLint
- `npm run lint:fix` - Fix ESLint errors automatically
- `npm run format` - Format code with Prettier

### Docker
- `npm run docker:up` - Start Docker services
- `npm run docker:down` - Stop Docker services
- `npm run docker:logs` - View Docker logs

### Database
- `npm run db:migrate` - Run database migrations
- `npm run db:seed` - Seed the database with test data
- `npm run db:reset` - Reset the database (drop all collections and recreate indexes)

## Project Structure

```
indexer/
├── src/
│   ├── config/         # Configuration
│   ├── models/         # Database models
│   ├── services/       # Business logic
│   ├── handlers/       # Event handlers
│   └── index.ts        # Entry point
├── scripts/           # Database management scripts
├── tests/            # Test files
└── docker-compose.yml # Docker configuration
```

## Architecture

The indexer service:
1. Connects to the blockchain via RPC
2. Listens for character-related events
3. Processes events through the event queue
4. Updates the MongoDB database accordingly
5. Provides an efficient query layer for character data

## Contributing

1. Create a feature branch
2. Make your changes
3. Run tests and linting
4. Submit a pull request

## License

ISC 