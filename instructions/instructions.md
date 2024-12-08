### Phase 1: MVP (Core Game Mechanics)

**Character & Items**  
- [x] **Character NFT (ERC-721AC)**  
  - [x] Implement hero minting (summoning heroes)  
  - [x] Store base stats, class, attributes, and equipment slots

- [x] **Equipment NFTs (ERC-1155 or ERC-721AC)**  
  - [x] Mint basic equipment (weapons/armor)  
  - [x] Integrate equip/unequip logic referencing character slots

**Economy & Quests**  
- [x] **In-Game Currency (ERC-20)**  
  - [x] Deploy token for rewards and marketplace trading  
  - [x] Mint tokens as quest rewards and integrate token sinks (fees, crafting)

- [x] **Quest Contract**  
  - [x] Implement start/complete quest functions  
  - [x] Reward in-game tokens and items

- [x] **Item Drop / Reward Contract with Chainlink VRF**  
  - [x] Integrate Chainlink VRF for unbiased random item drops  
  - [x] Configure subscription or request/response pattern for randomness requests  
  - [x] Ensure secure callback to distribute random items (e.g., rare swords, special potions)

**Basic Marketplace**  
- [x] **Auction House**  
  - [x] Implement basic buy/sell listings for NFTs using in-game token  
  - [x] Simple fee structure (could later tie into token burn or guild treasury)

**Testing & Deployment**  
- [x] Unit tests for Character, Equipment, Quests
- [x] Unit tests for Marketplace  
- [x] Test Chainlink VRF item drops on testnet  
- [ ] Deploy to mainnet after QA

---

### Phase 2: DeFi Expansion (AMM & Incentives)

**AMM Integration**  
- [ ] **AMM (Arcane Exchange)**  
  - [ ] Deploy Uniswap-like Factory & Router contracts.  
  - [ ] Create liquidity pools (in-game token paired with stable token or ETH).  
  - [ ] Enable token swaps.

- [ ] **Liquidity Provision (LP Tokens)**  
  - [ ] Players add liquidity, receive LP tokens.  
  - [ ] Front-end to show LP balances and pool details.

**Incentive Mechanisms**  
- [ ] **Staking / Farming Contract (e.g., MasterChef)**  
  - [ ] Stake LP tokens to earn extra in-game tokens.  
  - [ ] Set reward allocation and emission rates.

**Quest & Crafting Integration**  
- [ ] **AMM-based Quests**  
  - [ ] Certain quests require holding LP tokens.  
  - [ ] Enhanced item drops (via Chainlink VRF) for liquidity providers to incentivize participation.

- [ ] **AMM-driven Crafting**  
  - [ ] Some crafting recipes require LP tokens or AMM-derived resources.  
  - [ ] Special gear only obtainable through AMM engagement.

**Testing & Deployment**  
- [ ] Unit tests for AMM and incentive contracts.  
- [ ] Integration tests with MVP components.  
- [ ] Deploy to testnet, verify interactions, then mainnet.

---

### Phase 3: Hero Attributes (Titles, Abilities, Pets, Mounts) & Platform Benefits

**Titles & Ranks**  
- [ ] **Title NFTs or Metadata**  
  - [ ] Assign titles to Character NFTs.  
  - [ ] Titles grant platform-level benefits (e.g., +X bps on yield, reduced fees).  
  - [ ] Check attributes during AMM swaps, staking, or marketplace interactions.

**Abilities**  
- [ ] **Hero Abilities System**  
  - [ ] Store abilities as metadata or separate NFTs.  
  - [ ] Abilities might reduce AMM fees, improve crafting success, or affect Chainlink VRF request frequency/costs for better drops.

**Pets & Mounts**  
- [ ] **Pet NFT Contract**  
  - [ ] Pets provide yield boosts or better random drop odds (could integrate with Chainlink VRF to improve rarity chances).  
  - [ ] Configure different tiers of pets: common pets give slight boosts, legendary pets might improve drop rarities.

- [ ] **Mount NFT Contract**  
  - [ ] Mounts reduce quest fees, travel time, or LP lock-up periods.  
  - [ ] Possibly improve APR in staking contracts or offer fee rebates on marketplace trades.

**Integration & UI**  
- [ ] Calculate combined hero attributes and apply bonuses platform-wide.  
- [ ] Display hero attributes and benefits (extra APR, fee reductions, improved RNG outcomes) in the front-end.

**Testing & Deployment**  
- [ ] Unit tests for adding/removing titles, abilities, pets, mounts.  
- [ ] Integration tests to ensure correct adjustments to APR and fees.  
- [ ] Validate Chainlink VRF calls still function as expected with attribute modifiers.  
- [ ] Deploy after testnet validation.

---

### Phase 4: Guilds, DAOs, and Governance

**Guild Formation**  
- [ ] **Guild/DAO Contracts**  
  - [ ] Guild membership tokens (NFT or ERC-20).  
  - [ ] Voting, proposals, and treasury management (e.g., allocate funds to certain AMM pools).

**Guild & Hero Attributes**  
- [ ] **Guild Perks**  
  - [ ] Titles/abilities/pets/mounts may increase voting weight or proposal access.  
  - [ ] Exclusive guild-level quests requiring a hero with certain titles, offering premium drops (via VRF) or governance tokens.

**AMM & Governance Integration**  
- [ ] Guild votes determine reward allocation on AMM pools.  
- [ ] Guilds can vote on adjusting Chainlink VRF parameters (like gas limits) or the rarity distributions for certain item drops.

**Testing & Deployment**  
- [ ] Test guild proposals, voting, treasury functions.  
- [ ] Verify hero attributes affect governance as intended.  
- [ ] Deploy and gather community feedback.

---

### Phase 5: Flash Loans & Complex DeFi Mechanics

**Flash Loan Contracts**  
- [ ] **Flash Loan Pool**  
  - [ ] Implement a contract that offers flash loans of in-game tokens or other resources.  
  - [ ] Integrate appropriate fees and ensure security checks.

**Gamified Flash Loans**  
- [ ] **Flash Loan Quests**  
  - [ ] Special quests require taking a flash loan. If completed within the same transaction, the quest yields rare items (rolls via Chainlink VRF).  
  - [ ] Certain hero abilities or pets might reduce flash loan fees or guarantee improved item drop tables.

**Testing & Deployment**  
- [ ] Test flash loan logic thoroughly.  
- [ ] Ensure flash loan-based quests and VRF item drops work as intended.  
- [ ] Deploy after audits and testnet checks.

---

### Phase 6: Advanced DeFi Innovations

**Derivatives & Prediction Markets**  
- [ ] **Prediction Markets**  
  - [ ] Players bet on in-game events (boss spawns, quest completion rates).  
  - [ ] Hero attributes influence fees or payout rates.  
  - [ ] Chainlink VRF may be used to fairly determine event outcomes.

**Insurance & Safety Modules**  
- [ ] **Insurance Pools**  
  - [ ] Stake tokens to insure against quest failures or lost items.  
  - [ ] Titles/abilities/pets reduce insurance premiums or guarantee partial payouts.

**Cross-Chain & Layer 2**  
- [ ] **Bridging**  
  - [ ] Deploy to Layer 2 or other chains.  
  - [ ] Hero attributes that reduce bridging fees or provide better cross-chain rates.

**Dynamic Tokenomics**  
- [ ] **Adjustable Emission Rates & Fee Structures**  
  - [ ] DAO votes to change emission rates of rewards or modify Chainlink VRF subscription parameters.  
  - [ ] Hero titles influence voting power in these decisions.

**Testing & Deployment**  
- [ ] Complex scenario testing for prediction markets and insurance events.  
- [ ] Validate VRF integration in cross-chain or L2 environments (if applicable).  
- [ ] Deploy iteratively and refine based on community feedback.

### Phase 7: Advanced Gameplay & Social Features

**Raid System**  
- [ ] **Raid Contract**  
  - [ ] Implement multi-player raid mechanics requiring coordination
  - [ ] Complex boss mechanics with multiple phases
  - [ ] Raid-specific loot tables using Chainlink VRF
  - [ ] Raid progression and achievement tracking

**Social Systems**  
- [ ] **Friend System**  
  - [ ] Add/remove friends functionality
  - [ ] Friend-based quest bonuses
  - [ ] Social achievements and rewards

**Achievement System**  
- [ ] **Achievement NFTs**  
  - [ ] Implement achievement tracking and milestones
  - [ ] Special rewards for achievement completion
  - [ ] Achievement-based titles and perks

**PvP Arena**  
- [ ] **Arena Contract**  
  - [ ] Implement 1v1 and team-based PvP
  - [ ] Seasonal rankings and rewards
  - [ ] Integration with existing hero attributes and equipment
  - [ ] PvP-specific balancing mechanics

**Testing & Deployment**  
- [ ] Comprehensive testing of raid mechanics
- [ ] PvP balance testing and adjustments
- [ ] Social feature integration testing
- [ ] Security audit of new features
- [ ] Staged deployment to testnet then mainnet
