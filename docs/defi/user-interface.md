# 🖥️ DeFi UI Walkthrough

Welcome, brave adventurer! This scroll shall guide you through the mystical portals of our user interface, showing you how to navigate the sacred DeFi realms.

## The DeFi Dashboard 🏠

Upon entering the DeFi section of our game, you'll be greeted with the main dashboard:

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│   DEFI & DRAGONS                      Connect Wallet │
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│   ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌────────┐ │
│   │ Staking │  │ Liquidity│  │ Crafting│  │ Profile│ │
│   └─────────┘  └─────────┘  └─────────┘  └────────┘ │
│                                                     │
│   Your Assets:                                      │
│   - GOLD: 0                                         │
│   - WETH-GOLD LP: 0                                 │
│   - USDC-GOLD LP: 0                                 │
│   - WBTC-GOLD LP: 0                                 │
│                                                     │
│   Recent Transactions:                              │
│   - None yet                                        │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Connecting Your Wallet 🔌

First, you must connect your mystical pouch (wallet) to access the arcane features:

1. Click the "Connect Wallet" button in the top right
2. Select your preferred wallet provider (MetaMask, WalletConnect, etc.)
3. Approve the connection request in your wallet
4. Your address and token balances will appear once connected

```
✅ Connected: 0x1234...5678
```

## Providing Liquidity 💧

To craft powerful artifacts and earn rewards, you must first provide liquidity:

### Step 1: Navigate to Liquidity Section

Click on the "Liquidity" button in the main navigation:

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│   ADD LIQUIDITY                                     │
│                                                     │
│   Select Pair:                                      │
│   ┌─────────────────────────┐                       │
│   │ WETH-GOLD               ▼│                      │
│   └─────────────────────────┘                       │
│                                                     │
│   Amount:                                           │
│   ┌─────────────────────────┐  ┌─────────────────┐  │
│   │ 1.0                     │  │ WETH   Max: 5.0 │  │
│   └─────────────────────────┘  └─────────────────┘  │
│                                                     │
│   ┌─────────────────────────┐  ┌─────────────────┐  │
│   │ 100                     │  │ GOLD   Max: 500 │  │
│   └─────────────────────────┘  └─────────────────┘  │
│                                                     │
│   You will receive: ~9.8 WETH-GOLD LP tokens        │
│                                                     │
│   ┌─────────────────────────────────────────────┐   │
│   │              APPROVE TOKENS                 │   │
│   └─────────────────────────────────────────────┘   │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Step 2: Approve Token Spending

Click "APPROVE TOKENS" for each token you need to provide. You'll need to confirm these transactions in your wallet.

### Step 3: Add Liquidity

After approvals, the button will change to "ADD LIQUIDITY". Click it and confirm the transaction in your wallet.

```
Transaction successful! 
Added 1.0 WETH and 100 GOLD to liquidity pool.
Received: 9.8 WETH-GOLD LP tokens
```

## Staking LP Tokens 📈

Now that you have LP tokens, you can stake them to earn GOLD rewards:

### Step 1: Navigate to Staking Section

Click on the "Staking" button in the main navigation:

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│   STAKING POOLS                                     │
│                                                     │
│   ┌─────────────────────────────────────────────┐   │
│   │ WETH-GOLD Pool                    APR: 45%  │   │
│   │                                             │   │
│   │ Your Stake: 0 LP                            │   │
│   │ Pending Rewards: 0 GOLD                     │   │
│   │                                             │   │
│   │ ┌─────────┐  ┌──────────┐  ┌─────────────┐ │   │
│   │ │  STAKE  │  │ WITHDRAW │  │ CLAIM REWARDS│ │   │
│   │ └─────────┘  └──────────┘  └─────────────┘ │   │
│   └─────────────────────────────────────────────┘   │
│                                                     │
│   ┌─────────────────────────────────────────────┐   │
│   │ USDC-GOLD Pool                    APR: 35%  │   │
│   │                                             │   │
│   │ Your Stake: 0 LP                            │   │
│   │ Pending Rewards: 0 GOLD                     │   │
│   │                                             │   │
│   │ ┌─────────┐  ┌──────────┐  ┌─────────────┐ │   │
│   │ │  STAKE  │  │ WITHDRAW │  │ CLAIM REWARDS│ │   │
│   │ └─────────┘  └──────────┘  └─────────────┘ │   │
│   └─────────────────────────────────────────────┘   │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Step 2: Stake Your LP Tokens

Click "STAKE" on your chosen pool and enter the amount to stake:

```
┌───────────────────────────────────┐
│                                   │
│   STAKE WETH-GOLD LP              │
│                                   │
│   Amount:                         │
│   ┌─────────────────────────────┐ │
│   │ 9.8                Max ▼    │ │
│   └─────────────────────────────┘ │
│                                   │
│   Minimum Staking Period: 1 day   │
│   Estimated Rewards: ~0.5 GOLD/day│
│                                   │
│   ┌─────────────────────────────┐ │
│   │           STAKE             │ │
│   └─────────────────────────────┘ │
│                                   │
└───────────────────────────────────┘
```

Click "STAKE" and confirm the transaction in your wallet.

### Step 3: Monitor Your Rewards

Your staking position and pending rewards will update on the staking page:

```
Your Stake: 9.8 LP
Pending Rewards: 0.023 GOLD (accruing...)
```

### Step 4: Claim Rewards

When you wish to harvest your rewards, click "CLAIM REWARDS" and confirm the transaction:

```
Transaction successful!
Claimed 0.5 GOLD rewards
```

## Crafting Equipment with LP Tokens 🔨

With LP tokens, you can now craft powerful equipment:

### Step 1: Navigate to Crafting Section

Click on the "Crafting" button in the main navigation:

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│   CRAFTING WORKSHOP                                 │
│                                                     │
│   Available Recipes:                                │
│                                                     │
│   ┌─────────────────────────────────────────────┐   │
│   │ Ethereal Blade                              │   │
│   │ ┌─────┐                                     │   │
│   │ │  🗡️ │ +5 STR, +2 AGI, +0 MAG             │   │
│   │ └─────┘                                     │   │
│   │                                             │   │
│   │ Required:                                   │   │
│   │ - 50 WETH-GOLD LP                          │   │
│   │                                             │   │
│   │ Your LP: 9.8/50                             │   │
│   │                                             │   │
│   │ ┌─────────────┐                            │   │
│   │ │ INSUFFICIENT│                            │   │
│   │ └─────────────┘                            │   │
│   └─────────────────────────────────────────────┘   │
│                                                     │
│   ┌─────────────────────────────────────────────┐   │
│   │ Stable Pendant                              │   │
│   │ ┌─────┐                                     │   │
│   │ │  📿 │ +1 STR, +1 AGI, +5 MAG             │   │
│   │ └─────┘                                     │   │
│   │                                             │   │
│   │ Required:                                   │   │
│   │ - 25 USDC-GOLD LP                          │   │
│   │                                             │   │
│   │ Your LP: 0/25                               │   │
│   │                                             │   │
│   │ ┌─────────────┐                            │   │
│   │ │ INSUFFICIENT│                            │   │
│   │ └─────────────┘                            │   │
│   └─────────────────────────────────────────────┘   │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Step 2: Gather Required LP Tokens

Stake longer or provide more liquidity to gather the required LP tokens.

### Step 3: Craft the Item

Once you have enough LP tokens, the "INSUFFICIENT" button will change to "CRAFT". Click it and confirm the transaction.

```
┌───────────────────────────────────┐
│                                   │
│  CRAFT ETHEREAL BLADE?            │
│                                   │
│  This will consume:               │
│  - 50 WETH-GOLD LP tokens         │
│                                   │
│  ┌─────────────┐ ┌─────────────┐  │
│  │    CANCEL   │ │    CRAFT    │  │
│  └─────────────┘ └─────────────┘  │
│                                   │
└───────────────────────────────────┘
```

### Step 4: View Your Equipment

After crafting, you can view your new equipment in your character profile:

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│   CHARACTER PROFILE                                 │
│                                                     │
│   Mage Level 5                                      │
│   ┌─────┐                                           │
│   │ 🧙‍♂️ │ Stats:                                    │
│   └─────┘ - Strength: 10 (+5)                       │
│           - Agility: 10 (+2)                        │
│           - Magic: 15 (+0)                          │
│                                                     │
│   Equipment:                                        │
│   - Weapon: Ethereal Blade 🗡️                       │
│   - Armor: None                                     │
│   - Accessory: None                                 │
│                                                     │
│   DeFi Positions:                                   │
│   - WETH-GOLD Pool: 0 LP (used for crafting)        │
│   - USDC-GOLD Pool: 0 LP                            │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## Troubleshooting Common UI Issues 🔧

### Wallet Not Connecting

If your wallet isn't connecting properly:

1. Refresh the page
2. Make sure you're on the right network
3. Check if your wallet has the latest update

### Transactions Not Confirming

If your transactions are pending for too long:

1. Check your gas settings in your wallet
2. Look for any approval requests that might be waiting
3. Check the network status for congestion

### Unable to See LP Tokens

If your LP tokens aren't showing up:

1. Make sure the transaction was confirmed
2. Click the "Refresh" button next to your balance
3. Try adding the LP token to your wallet manually with the token address

## Mobile Interface 📱

Our interface is fully responsive and works on mobile devices:

```
┌─────────────────────────┐
│                         │
│ DEFI & DRAGONS  ☰ Menu │
│                         │
├─────────────────────────┤
│                         │
│ Your Assets:            │
│ - GOLD: 0.5             │
│ - WETH-GOLD LP: 9.8     │
│                         │
│ ┌─────┐ ┌────────┐      │
│ │Stake│ │Liquidity│     │
│ └─────┘ └────────┘      │
│                         │
│ ┌──────┐ ┌───────┐      │
│ │Craft │ │Profile│      │
│ └──────┘ └───────┘      │
│                         │
└─────────────────────────┘
```

May your journey through our interface be smooth and rewarding, brave adventurer! 🌟 