# Combat Mechanics

This document details the combat system in DeFi & Dragons.

## Initiating Combat

*(Explain how players enter combat. E.g., clicking on monsters, entering specific zones, PvP challenges)*

*   **PvE (Player vs. Environment):** Encountering monsters in the world, dungeons, or specific event areas.
*   **PvP (Player vs. Player):** Challenging other players, entering designated PvP arenas, guild wars (if applicable).

## Combat Turn Structure (If Applicable)

*(Describe if combat is turn-based, real-time, or a hybrid.)*

*   **Turn-Based:**
    *   Initiative: How is turn order determined (e.g., Speed stat, randomness)?
    *   Player Actions: What can a player do on their turn (e.g., Attack, Defend, Use Skill, Use Item, Flee)?
    *   Enemy Actions: How do enemies (AI) decide their actions?
*   **Real-Time:**
    *   Action Bars/Cooldowns: Do abilities have cooldowns?
    *   Movement/Positioning: Is positioning important? How does movement work?
    *   Targeting: How are targets selected?

## Core Combat Stats

Referencing the [Stats System](./stats-system.md), the key stats influencing combat are:

*   **Health Points (HP):** Determines survivability. Combat ends for a participant when HP reaches 0.
*   **Mana Points (MP) / Energy / Rage:** Resource used for skills/abilities.
*   **Attack Power / Strength:** Influences damage dealt by physical attacks.
*   **Magic Power / Intelligence:** Influences damage/effectiveness of magical abilities.
*   **Defense / Armor:** Reduces damage taken from physical attacks.
*   **Magic Resistance:** Reduces damage taken from magical attacks.
*   **Speed / Agility / Dexterity:** May influence turn order, dodge chance, attack speed, or accuracy.
*   **Accuracy:** Chance to hit the target.
*   **Evasion / Dodge:** Chance to avoid an incoming attack.
*   **Critical Hit Chance:** Chance to deal bonus damage.
*   **Critical Hit Damage:** Multiplier for bonus damage on critical hits.

*(Add or remove stats specific to your game)*

## Damage Calculation

*(Provide a simplified overview or the exact formula if desired)*

*   **Physical Damage Example:** `(Attacker's Attack Power * Skill Multiplier) - Target's Defense`
*   **Magical Damage Example:** `(Attacker's Magic Power * Skill Multiplier) - Target's Magic Resistance`
*   Considerations: Base weapon damage, buffs/debuffs, elemental affinities, critical hits.

## Skills and Abilities

*   **Types:** Active skills (require activation), passive skills (always active), buffs (positive effects), debuffs (negative effects).
*   **Resource Costs:** MP, Energy, Cooldowns.
*   **Effects:** Damage, healing, status effects (stun, poison, burn, freeze), stat modifications.
*   **Learning/Acquiring:** How do players get new skills (leveling up, skill trees, item drops, trainers)?

## Status Effects

*(List common status effects and their impact)*

*   **Poison:** Damage over time.
*   **Burn:** Damage over time (potentially different type or interaction).
*   **Stun:** Target cannot act for a duration.
*   **Freeze/Paralysis:** Target cannot act.
*   **Silence:** Target cannot use magical abilities.
*   **Bleed:** Damage over time, potentially increased by movement.
*   **Buffs:** Increased Attack, Defense, Speed, etc.
*   **Debuffs:** Decreased Attack, Defense, Speed, etc.

## Items in Combat

*   **Consumables:** Potions (HP/MP recovery), status effect cures, temporary buffs.
*   **Equipment:** Weapons, armor, and accessories provide passive stat bonuses and sometimes active abilities.

## Combat Outcomes

*   **Victory (PvE):**
    *   Experience Points (EXP)
    *   Loot Drops (Items, Currency like $GOLD)
    *   Quest Progression
*   **Defeat (PvE):**
    *   Penalties (EXP loss, item durability loss, respawn timer, respawn location).
    *   *On-chain implications? (e.g., temporary NFT lock, small token burn?)*
*   **PvP Outcomes:**
    *   Ranking changes.
    *   Rewards (Tokens, PvP points).
    *   Penalties (Loss of rank, temporary debuffs?).

## Advanced Concepts (Optional)

*   Elemental Strengths/Weaknesses
*   Combo Systems
*   Threat/Aggro Mechanics
*   Environmental Effects

## On-Chain vs. Off-Chain Combat

*(Clarify which parts of combat happen on the blockchain vs. off-chain)*

*   **Likely On-Chain:** Major outcomes, significant rewards (NFTs, large token amounts), high-stakes PvP results.
*   **Likely Off-Chain:** Individual attack calculations, minor actions, low-level PvE for performance reasons. Results might be batched and settled on-chain periodically.
*   **Commit-Reveal Schemes:** Potential use for PvP to ensure fairness without revealing moves prematurely.

## Related Links

*   [Stats System](./stats-system.md)
*   [Character Progression](./character-progression.md)
*   [Equipment & Items](./item-system.md) *(Link to be created)* 