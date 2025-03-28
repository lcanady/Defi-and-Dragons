# 🌟 Getting Started with DeFi & Dragons Contracts

Welcome, developer! This guide provides the essential steps to start interacting with the DeFi & Dragons smart contracts.

## Prerequisites

Before you begin, ensure you have:

1.  **Wallet:** A compatible Ethereum wallet (like MetaMask) configured for the target network (e.g., testnet, mainnet).
2.  **Contract Addresses:** The deployed addresses of the core contracts, primarily the `GameFacade` address. These are usually obtained from the deployment artifacts or a configuration file.
3.  **Interaction Tool:** A way to interact with the contracts, such as:
    *   **Ethers.js/Web3.js:** For building frontend or backend integrations.
    *   **Foundry `cast` / Hardhat Console:** For direct command-line interaction.

## 1. Connecting to the Game Facade

The `GameFacade` contract is your primary entry point for most game interactions. Obtain its address and ABI (Application Binary Interface).

```typescript
// Example using Ethers.js
import { ethers } from "ethers";
import GameFacadeAbi from "./abi/GameFacade.json"; // Assuming you have the ABI

const provider = new ethers.providers.Web3Provider(window.ethereum);
const signer = provider.getSigner();

const gameFacadeAddress = "0x..."; // Replace with actual GameFacade address
const gameFacade = new ethers.Contract(gameFacadeAddress, GameFacadeAbi, signer);

const playerAddress = await signer.getAddress();
```

## 2. Creating Your Character

Forge your unique Character NFT. Choose an alignment (Strength, Agility, or Magic) which influences your starting stats.

- **Stats:** Characters start with 45 total points distributed across Strength, Agility, and Magic (each between 5-18). The contract handles random generation and balancing based on alignment.
- **Wallet:** A dedicated `CharacterWallet` contract is automatically created to manage this character's equipment.

```typescript
// Example using Ethers.js
import { Types } from "./interfaces/Types"; // Assuming you have Type definitions

async function createCharacter(alignment: Types.Alignment) {
    try {
        console.log(`Creating character with alignment: ${alignment}...`);
        const tx = await gameFacade.createCharacter(alignment);
        console.log("Transaction sent:", tx.hash);

        const receipt = await tx.wait();
        console.log("Transaction confirmed.");

        // Find the CharacterCreated event to get the tokenId and wallet address
        const event = receipt.events?.find(e => e.event === "CharacterCreated");
        const tokenId = event?.args?.tokenId;
        const characterWalletAddress = event?.args?.wallet;

        if (tokenId) {
            console.log(`Character Created! Token ID: ${tokenId.toString()}`);
            console.log(`Character Wallet Address: ${characterWalletAddress}`);
            return tokenId;
        } else {
            console.error("Could not find CharacterCreated event.");
            return null;
        }
    } catch (error) {
        console.error("Character creation failed:", error);
        return null;
    }
}

// Choose alignment (0: STRENGTH, 1: AGILITY, 2: MAGIC)
const alignmentChoice = Types.Alignment.STRENGTH;
const characterId = await createCharacter(alignmentChoice);
```

## 3. Viewing Character Details

Check your character's stats, state (level, health), and equipped items.

```typescript
// Example using Ethers.js
async function viewCharacter(tokenId: ethers.BigNumber) {
    if (!tokenId) return;

    try {
        const { stats, equipment, state } = await gameFacade.getCharacterDetails(tokenId);
        console.log("--- Character Details --- C ID:", tokenId.toString());
        console.log("Stats:", {
            strength: stats.strength.toString(),
            agility: stats.agility.toString(),
            magic: stats.magic.toString(),
        });
        console.log("Equipment:", {
            weaponId: equipment.weaponId.toString(),
            armorId: equipment.armorId.toString(),
        });
        console.log("State:", {
            level: state.level,
            health: state.health.toString(),
            alignment: state.alignment,
            // ... other state fields
        });
    } catch (error) {
        console.error("Failed to get character details:", error);
    }
}

if (characterId) {
    await viewCharacter(characterId);
}
```

## 4. Basic Gameplay Actions (via Facade)

Most core actions are performed through the `GameFacade`.

### Equipping Items
*Requires owning the Character NFT and the Equipment NFTs. The Character's Wallet must be approved to manage the Equipment NFTs.*

```typescript
// Assume characterId, weaponNftId, armorNftId are known
// Ensure approvals are set before calling!
await gameFacade.equipItems(characterId, weaponNftId, armorNftId);

// To unequip weapon only:
await gameFacade.unequipItems(characterId, true, false);
```

### Starting & Completing Quests

```typescript
// Assume characterId and a valid questId are known
await gameFacade.startQuest(characterId, questId);

// ... perform quest actions ...

// Attempt to complete the quest
await gameFacade.completeQuest(characterId, questId);
// Monitor QuestCompleted event for success and potential item drop requestId
```

### Requesting Item Drops
Often triggered automatically after quest completion, but can be requested.

```typescript
const dropRateBonus = 0; // Example: No bonus
const requestId = await gameFacade.requestRandomDrop(dropRateBonus);
// Monitor ItemDropped / ItemClaimed events using the requestId
```

### Marketplace Actions
*Requires owning the listed item and approving the Marketplace contract for the NFT. Purchasing requires approving the Marketplace for the Game Token.*

```typescript
// Assume equipmentNftId, price in game tokens (wei), amount are known
await gameFacade.listItem(equipmentNftId, price, amount);

// Assume listingId is known for an active listing
await gameFacade.purchaseItem(equipmentNftId, listingId, amount);
```

### Social Actions (Team Quests)
*Requires owning all characters being added to the team.*

```typescript
// Assume teamQuestId and member character IDs are known
await gameFacade.formTeam(teamQuestId, [charId1, charId2, charId3]);

// Record contribution (may require specific permissions/callers)
await gameFacade.recordContribution(teamQuestId, contributingCharId, contributionValue);
```

## Next Steps

Now that you have the basics, explore the detailed documentation:

-   **API Reference:** Dive deep into specific contract functions:
    -   [`GameFacade`](../api-reference/game-facade.md)
    -   [`Character`](../api-reference/character.md)
    -   [`Equipment`](../api-reference/equipment.md)
    -   [`Quest System`](../api-reference/quest.md)
    -   [`Combat System`](../api-reference/combat.md)
-   **Gameplay Mechanics:** Understand the rules and systems:
    -   [Core Gameplay Loop](../gameplay/index.md)
    -   [Stats System](../gameplay/stats-system.md)
    -   [Social Features](../gameplay/social.md)
-   **DeFi Integrations:** Learn how DeFi protocols connect:
    -   [`DeFi Overview`](../defi/index.md)

## Need Help?

-   Join our [Discord](https://discord.gg/defi-dragons) (replace with actual link if available) for community support.
-   Check the [FAQ](../faq.md).
-   Consult the [Troubleshooting Guide](../troubleshooting.md).

May your code compile and your transactions succeed! 💻✨ 