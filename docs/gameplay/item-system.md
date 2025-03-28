# Item System

This document covers the item system in DeFi & Dragons, including equipment, consumables, inventory management, and crafting.

## Item Types

Items are broadly categorized:

*   **Equipment:** Items characters can wear to gain stats and effects.
    *   **Weapons:** (Swords, bows, staffs, etc.) Primarily affect offensive capabilities.
    *   **Armor:** (Helmets, chestplates, leggings, boots, shields) Primarily affect defensive capabilities.
    *   **Accessories:** (Rings, amulets, capes) Often provide unique stats or effects.
*   **Consumables:** Single-use items.
    *   **Potions:** Restore HP, MP, or cure status effects.
    *   **Scrolls:** Cast spells or provide temporary buffs.
    *   **Food/Drink:** Provide temporary buffs or regeneration.
*   **Crafting Materials:** Resources used in crafting recipes (ores, herbs, wood, monster parts).
*   **Quest Items:** Items specifically required for completing quests; often cannot be traded or dropped.
*   **Currency:** In-game tokens like $GOLD (ERC-20) or other special currencies.
*   **NFT Items:** Unique items represented as NFTs (ERC-721 or ERC-1155), potentially including high-tier equipment, cosmetic skins, land plots, or character unlocks.

## Acquiring Items

Players can obtain items through:

*   **Monster Drops:** Defeating enemies.
*   **Quest Rewards:** Completing quests.
*   **Crafting:** Creating items using recipes and materials.
*   **Gathering:** Collecting resources from the environment (mining, herbalism, woodcutting).
*   **Trading:** Exchanging items with other players (requires an on-chain marketplace or P2P transfer system for NFTs/Tokens).
*   **Purchasing:** Buying items from NPC vendors or player-run shops/marketplaces.
*   **Minting/Events:** Special events or promotions might allow minting or reward unique items.

## Inventory Management

*   **Inventory Slots:** Players have a limited number of slots to carry items.
*   **Stacking:** Many items (consumables, materials, currency) can stack up to a certain limit per slot.
*   **Equipment Slots:** Characters have specific slots for equipping different types of gear (Head, Chest, Legs, Feet, Main Hand, Off-Hand, Ring 1, Ring 2, Amulet, etc.).
*   **Bank/Stash:** A storage space, potentially larger than the main inventory, accessible in safe zones (towns). Might require on-chain transactions for NFT/token storage.
*   **Sorting/Filtering:** UI features to help manage the inventory.

## Equipment

*   **Stats:** Equipment provides bonuses to core combat stats (see [Stats System](./stats-system.md) and [Combat Mechanics](./combat-mechanics.md)).
*   **Rarity:** Items may have different rarity levels (Common, Uncommon, Rare, Epic, Legendary) influencing their stats and potential effects.
*   **Durability (Optional):** Equipment might degrade with use and require repairs.
*   **Set Bonuses (Optional):** Equipping multiple items from the same set might grant additional bonuses.
*   **Level Requirements (Optional):** Some equipment might only be usable by characters above a certain level.
*   **Soulbinding (Optional):** Some items might become permanently bound to a character once equipped, preventing trade.
*   **NFT Equipment:** High-end or unique equipment might be represented as NFTs, allowing for true ownership and trading on marketplaces.
    *   Metadata: NFT metadata stores the item's stats, rarity, appearance, history.

## Crafting (Optional)

*(If your game includes crafting, detail it here)*

*   **Recipes:** Players learn or find recipes to craft specific items.
*   **Materials:** Crafting requires specific types and quantities of crafting materials.
*   **Crafting Stations:** May require specific locations or stations (forge, alchemy lab) to craft certain items.
*   **Skills:** Crafting might be tied to specific skills (Blacksmithing, Alchemy, Jewelcrafting) that need to be leveled up.
*   **Success/Failure Chance:** Crafting might have a chance to fail or produce items of varying quality.

## Item Representation (On-Chain vs. Off-Chain)

*   **NFTs (ERC-721/ERC-1155):** Ideal for unique, high-value equipment, land, cosmetics. Enables true ownership and external trading.
*   **ERC-20 Tokens:** Fungible items like currency ($GOLD), common crafting materials (stackable).
*   **Off-Chain Database:** Standard, non-blockchain items (common gear, basic consumables) managed by a traditional game server for efficiency. May be "bridged" or converted to on-chain items under certain conditions.
*   **Hybrid:** Off-chain representation for general use, with an option to mint specific items as NFTs for trading or withdrawal.

## Related Links

*   [Combat Mechanics](./combat-mechanics.md)
*   [Stats System](./stats-system.md)
*   [Quest System](./quest-system.md)
*   [Gold Token](../defi/gold-token.md) 