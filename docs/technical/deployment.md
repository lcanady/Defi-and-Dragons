# Contract Deployment

This guide outlines the process for deploying the DeFi & Dragons smart contracts using Foundry.

## Prerequisites

*   [Foundry installed](https://book.getfoundry.sh/getting-started/installation)
*   Project dependencies installed (`forge install` or `npm install`/`yarn install` if managed via package.json)
*   Compiled contracts (`forge build`)
*   Environment variables set up (`.env` file) containing:
    *   `RPC_URL_<NETWORK>`: RPC endpoint URL for the target network (e.g., `RPC_URL_SEPOLIA`, `RPC_URL_MAINNET`).
    *   `PRIVATE_KEY`: Private key of the deployer wallet ( **handle with extreme care** ).
    *   `ETHERSCAN_API_KEY_<NETWORK>` (Optional): Etherscan API key for contract verification.

**Security Note:** Never commit your `.env` file or private keys to version control.

## Deployment Strategy

*(Describe the overall deployment strategy. E.g., single script deploys all, multiple scripts for different modules, using proxies, factory pattern?)*

*   **Scripts:** Deployment logic is typically encapsulated in Solidity scripts within the `script/` directory.
*   **Proxy Pattern (If Used):** Explain if contracts use upgradeable proxies (e.g., UUPS or Transparent) and how implementations are deployed and linked.
*   **Initialization:** Detail any post-deployment initialization steps required (e.g., setting roles, configuring parameters, transferring ownership).

## Deployment Scripts

*(List and briefly describe the main deployment scripts)*

*   `script/DeployAll.s.sol`: (Example) Deploys the core set of contracts.
*   `script/DeployToken.s.sol`: (Example) Deploys only the token contracts.
*   `script/UpgradeContract.s.sol`: (Example) Handles deploying a new implementation and upgrading a proxy.

## Deployment Process (Using `forge script`)

1.  **Select Network:** Choose the target network (e.g., `anvil`, `sepolia`, `mainnet`).
2.  **Configure `.env`:** Ensure the `RPC_URL_<NETWORK>` and `PRIVATE_KEY` are correctly set for the target network.
3.  **Run the Deployment Script:** Execute the relevant script using `forge script`.

    ```bash
    # Example: Deploying all contracts to Sepolia testnet
    forge script script/DeployAll.s.sol:DeployAll --rpc-url $RPC_URL_SEPOLIA --private-key $PRIVATE_KEY --broadcast --verify -vvvv
    ```

    *   `script/DeployAll.s.sol:DeployAll`: Specifies the script file and the contract containing the `run()` function.
    *   `--rpc-url $RPC_URL_SEPOLIA`: Uses the RPC URL from your environment variables.
    *   `--private-key $PRIVATE_KEY`: Uses the private key from your environment variables.
    *   `--broadcast`: Signs and sends the transactions to the network.
    *   `--verify`: (Optional) Attempts to verify the deployed contracts on Etherscan (requires `--etherscan-api-key` or env var).
    *   `-vvvv`: Increases verbosity for detailed output, helpful for debugging.

4.  **Review Output:** `forge script` will output the addresses of the deployed contracts and transaction hashes.
5.  **Record Addresses:** Store the deployed contract addresses securely. Often, Foundry saves deployment details in the `broadcast/` directory.
6.  **Verification (If not done with `--verify`):** Manually verify contracts on Etherscan if needed, using the addresses and constructor arguments.

    ```bash
    # Example: Verifying a specific contract
    forge verify-contract --chain-id <CHAIN_ID> <CONTRACT_ADDRESS> src/MyContract.sol:MyContract --etherscan-api-key $ETHERSCAN_API_KEY_<NETWORK>
    ```

7.  **Post-Deployment Setup:** Execute any necessary initialization transactions (e.g., setting roles using `cast send` or another script).

    ```bash
    # Example: Calling a setup function using cast
    cast send <CONTRACT_ADDRESS> "initialize(address,uint256)" <ARG_1> <ARG_2> --rpc-url $RPC_URL_SEPOLIA --private-key $PRIVATE_KEY
    ```

## Target Networks

*(List the networks the project is intended to be deployed on)*

*   **Local Development:** Anvil
*   **Testnet(s):** Sepolia, Goerli, Polygon Mumbai, etc.
*   **Mainnet(s):** Ethereum Mainnet, Polygon PoS, Arbitrum One, etc.

Provide specific Chain IDs and links to block explorers if helpful.

## Updating Contract Addresses

After deployment, update the contract addresses in configuration files, frontend applications, and relevant documentation (e.g., `docs/defi/contract-addresses.md`).

## Related Links

*   [Foundry Book: Deploying with Scripts](https://book.getfoundry.sh/tutorials/solidity-scripting)
*   [Foundry Book: Contract Verification](https://book.getfoundry.sh/tutorials/verification)
*   [Smart Contract Architecture](./smart-contract-architecture.md)
*   [Upgradeability Guide](./upgradeability.md) *(Link to be created)* 