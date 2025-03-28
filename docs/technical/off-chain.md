# Off-Chain Infrastructure

While DeFi & Dragons leverages blockchain for core asset ownership and specific mechanics, certain components operate off-chain for performance, user experience, or practical reasons. This document outlines the off-chain infrastructure.

## Overview

*(Provide a high-level summary of the off-chain systems and their purpose. E.g., game server for real-time actions, indexing service for querying blockchain data, frontend application.)*

## Components

*(Detail each major off-chain component)*

### 1. Game Server (Optional)

*   **Purpose:** Manages real-time gameplay aspects not suitable for direct blockchain interaction due to latency or cost.
    *   Examples: Player movement, chat, low-stakes PvE combat calculations, managing temporary game state.
*   **Technology Stack:** *(e.g., Node.js, Python/Django, Go, C#/.NET)*
*   **Database:** *(e.g., PostgreSQL, MongoDB, Redis)* Used for storing temporary state, player session data, non-critical game data.
*   **Interaction with Blockchain:**
    *   Reads blockchain state via RPC calls (e.g., checking NFT ownership, token balances).
    *   Submits transactions on behalf of the user (requires user signature) or a server wallet for specific actions (e.g., distributing minor rewards, settling batched results).
    *   Listens for blockchain events.
*   **Security:** Requires protection against standard web application vulnerabilities (DoS, injection attacks, authentication issues).

### 2. Indexing Service / Subgraph

*   **Purpose:** Efficiently query blockchain data and events for display in the frontend or use by the game server. Avoids slow/expensive direct RPC calls for complex queries.
*   **Technology:**
    *   **The Graph:** A decentralized indexing protocol. Requires creating a subgraph manifest (`subgraph.yaml`), GraphQL schema (`schema.graphql`), and AssemblyScript mappings (`mapping.ts`).
    *   **Custom Indexer:** A bespoke backend service that listens to blockchain events using libraries like Ethers.js/Web3.js and stores processed data in a database (e.g., PostgreSQL).
*   **Data Indexed:** *(e.g., Character NFT details, item ownership, market listings, $GOLD balances, staking positions, quest completion events)*
*   **Access:** Provides a GraphQL or REST API for the frontend/game server.

### 3. Frontend Application

*   **Purpose:** The user interface for interacting with the game.
*   **Technology Stack:** *(e.g., React, Vue, Angular, Svelte, Next.js, Phaser.js, Unity/Unreal Engine via WebGL)*
*   **Interaction with Blockchain:**
    *   Connects to user wallets (MetaMask, etc.) using libraries like Ethers.js, Web3Modal, RainbowKit, Wagmi.
    *   Reads data from the Indexing Service API.
    *   Constructs transactions and prompts the user to sign/send them via their wallet.
*   **Interaction with Game Server:** Communicates via WebSockets or REST APIs for real-time updates and off-chain actions.

### 4. Relayers / Meta-Transactions (Optional)

*   **Purpose:** Enable gasless transactions for the user. The user signs a message off-chain, and a relayer service pays the gas fee to submit the transaction.
*   **Technology:** Requires specific contract support (e.g., EIP-2771 `_msgSender()` context) and a trusted relayer infrastructure.
*   **Use Cases:** Improving onboarding, subsidizing specific actions (e.g., first quest completion).

### 5. IPFS / Decentralized Storage

*   **Purpose:** Storing NFT metadata (JSON files, images, animations) off-chain in a decentralized manner.
*   **Technology:** IPFS (InterPlanetary File System), Arweave.
*   **Usage:** Token URIs in ERC-721/ERC-1155 contracts point to metadata files stored on IPFS/Arweave (e.g., `ipfs://<CID>/<TOKEN_ID>.json`).

## Data Flow Example (e.g., Completing a Quest with NFT Reward)

1.  **Player Action (Frontend):** Player clicks "Complete Quest" in the UI.
2.  **Off-Chain Logic (Game Server - Optional):** Server verifies off-chain objectives (if any).
3.  **Transaction Prep (Frontend/Server):** Prepare the `completeQuest` transaction.
4.  **User Signature (Wallet):** Frontend prompts the user's wallet to sign the transaction.
5.  **Transaction Broadcast:** Wallet sends the signed transaction to the blockchain RPC endpoint.
6.  **Blockchain Execution (Smart Contract):** `completeQuest` function executes on-chain, potentially minting an NFT reward.
7.  **Event Emitted (Smart Contract):** Contract emits `QuestCompleted` and `Transfer` (for NFT) events.
8.  **Indexing (Subgraph/Indexer):** The indexing service detects the events.
9.  **Database Update (Indexer):** Indexer processes events and updates its database (e.g., marks quest complete, records NFT ownership).
10. **UI Update (Frontend):** Frontend queries the Indexing Service API and updates to show the completed quest and the new NFT in the player's inventory.

## Trust Assumptions & Security

*   **Game Server:** Users trust the game server for the fair execution of off-chain logic. Compromise could lead to unfair advantages or state inconsistencies (though valuable assets remain secured by the blockchain).
*   **Indexing Service:** Users trust the indexer to provide accurate blockchain data. For critical actions, data should always be verified on-chain if possible.
*   **Relayers:** Users trust relayers not to censor transactions (though the signed message itself dictates the action).

## Related Links

*   [The Graph](https://thegraph.com/)
*   [IPFS](https://ipfs.tech/)
*   [Chainlink (For Oracles)](https://chain.link/)
*   [Smart Contract Architecture](./smart-contract-architecture.md) 