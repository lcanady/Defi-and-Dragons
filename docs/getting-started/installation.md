# Installation

This guide provides instructions on how to install and set up the necessary components to run or interact with DeFi & Dragons.

## Prerequisites

Before you begin, ensure you have the following installed:

*   **Node.js:** [Specify version, e.g., v18.x or later] - [Link to Node.js website](https://nodejs.org/)
*   **npm** or **yarn:** Included with Node.js or install separately ([Link to Yarn](https://yarnpkg.com/))
*   **Git:** [Link to Git website](https://git-scm.com/)
*   **Foundry:** [Link to Foundry installation guide](https://book.getfoundry.sh/getting-started/installation)
*   **Metamask** (or other compatible wallet): [Link to Metamask website](https://metamask.io/)

*Add any other specific prerequisites, like operating system requirements or other dependencies.*

## Installation Steps

### 1. Clone the Repository

```bash
git clone https://github.com/lcanady/defi-and-dragons.git
cd defi-and-dragons
```

### 2. Install Dependencies

Using npm:
```bash
npm install
```

Or using yarn:
```bash
yarn install
```

### 3. Set Up Environment Variables

*Explain how to set up any necessary environment variables. This often involves copying a `.env.example` file to `.env` and filling in required values (API keys, private keys for testing, RPC URLs, etc.).*

Example:
```bash
cp .env.example .env
```
Then, edit the `.env` file with your specific configuration.

### 4. Compile Contracts (If applicable)

If you need to compile the smart contracts locally:
```bash
forge build
```

### 5. Run Local Development Node (Optional)

If you plan to test locally using Anvil:
```bash
anvil
```
*Make sure to configure your `.env` or application settings to point to the local RPC URL (usually `http://127.0.0.1:8545`).*

### 6. Deploy Contracts (Optional)

*Provide instructions or link to the deployment guide (`docs/technical/deployment.md`) on how to deploy contracts to a testnet or mainnet.*

```bash
# Example using forge script
forge script script/DeployContracts.s.sol --rpc-url <YOUR_RPC_URL> --private-key <YOUR_PRIVATE_KEY> --broadcast
```

## Next Steps

*   Proceed to [Wallet Setup](./wallet-setup.md)
*   Try the [Tutorial](./tutorial.md)
*   Explore the [Gameplay Overview](../gameplay/index.md) 