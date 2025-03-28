# Wallet Setup

This guide explains how to set up a crypto wallet, specifically MetaMask, to interact with DeFi & Dragons.

## Why You Need a Wallet

A crypto wallet is required to:

*   Hold your game tokens (e.g., $GOLD, NFTs representing characters or items).
*   Interact with the game's smart contracts on the blockchain.
*   Sign transactions to perform in-game actions that have on-chain consequences.

## Installing MetaMask

MetaMask is a popular browser extension and mobile app wallet.

1.  **Install the Extension/App:** Go to the [MetaMask website](https://metamask.io/download/) and follow the instructions to install it for your browser (Chrome, Firefox, Brave, Edge) or mobile device (iOS, Android).
2.  **Create a Wallet:** Open MetaMask and click "Get Started". Choose "Create a Wallet".
3.  **Set a Password:** Create a strong password.
4.  **Secure Your Wallet (CRITICAL):**
    *   MetaMask will show you a **Secret Recovery Phrase** (also called a seed phrase). This is a list of 12 words.
    *   **Write this phrase down** on paper and store it somewhere extremely safe and secret.
    *   **NEVER share this phrase with anyone.** Anyone with this phrase can access your wallet and steal your funds/assets.
    *   **DO NOT store it digitally** (e.g., in a text file, email, cloud storage) where it could be hacked.
    *   MetaMask will ask you to confirm the phrase by selecting the words in the correct order.

## Connecting MetaMask to the Correct Network

DeFi & Dragons runs on a specific blockchain network (e.g., Ethereum Mainnet, Polygon, Arbitrum, a specific testnet like Sepolia, or even a local development network).

1.  **Open MetaMask.**
2.  **Click the network dropdown menu** at the top (it usually defaults to "Ethereum Mainnet").
3.  **Select the Network:**
    *   If the required network (e.g., Polygon Mainnet) is listed, simply select it.
    *   If it's not listed, click "Add Network".
    *   You may need to manually enter the network details (Network Name, New RPC URL, Chain ID, Currency Symbol, Block Explorer URL). *[Provide the specific details for the network(s) DeFi & Dragons uses, or link to a resource like Chainlist.org]*. For example, for a local Anvil node:
        *   Network Name: `Anvil Local`
        *   New RPC URL: `http://127.0.0.1:8545`
        *   Chain ID: `31337`
        *   Currency Symbol: `ETH`

## Connecting Your Wallet to the Game/dApp

*(This section depends on whether you have a web interface/dApp)*

1.  Navigate to the DeFi & Dragons web application.
2.  Look for a "Connect Wallet" button (usually in the top right corner).
3.  Click the button. MetaMask (or your chosen wallet) should pop up.
4.  Select the account(s) you want to use with the game.
5.  Approve the connection request.

Your wallet address should now be displayed in the application, indicating you are connected.

## Funding Your Wallet (Testnet/Mainnet)

To perform transactions on a blockchain network (except potentially a local dev node), you'll need the network's native currency (e.g., ETH on Ethereum, MATIC on Polygon) to pay for gas fees.

*   **Testnets:** Use a faucet specific to the testnet (e.g., Sepolia Faucet, Polygon Mumbai Faucet) to get free test tokens. *[Provide links to relevant faucets]*. 
*   **Mainnets:** You will need to acquire real cryptocurrency through an exchange (like Coinbase, Binance, Kraken) and send it to your MetaMask wallet address.
*   **Game Tokens:** Explain how users acquire initial game tokens ($GOLD, starter characters, etc.), whether through purchase, a faucet, or initial distribution.

## Next Steps

*   Understand [Character Wallets](./character-wallet.md) if applicable.
*   Begin the [Tutorial](./tutorial.md).
*   Review the [Installation Guide](./installation.md). 