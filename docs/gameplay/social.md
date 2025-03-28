# The Fellowship Guide: Teamwork & Referrals 🤝

Welcome, adventurer! Collaboration and community are vital in DeFi & Dragons. This guide explains how you can team up with fellow players for greater challenges and rewards, and how you can help the realm grow through referrals.

## ⚔️ Team Quests

Some challenges are too great for a single hero. Team Quests allow groups of players to pool their efforts towards a common objective, sharing in the glory and spoils.

### How Team Quests Work

1.  **Quest Definition:** Special `TeamQuest` templates are created (by admins) defining the quest's goal (e.g., a total contribution target like defeating X monsters or collecting Y resources as a group), the required team size (min/max), the duration, and the rewards.
    *   See: [`createTeamQuest` in SocialQuest API](./../api-reference/quest.md#createteamquest)
2.  **Forming a Team:** A player (who must own all characters being added) can form a team specifically for a chosen `TeamQuest`. They provide the character IDs of the members.
    *   The system checks if the team size is valid and if the characters are available.
    *   See: [`formTeam` in SocialQuest API](./../api-reference/quest.md#formteam)
3.  **Contributing:** As team members participate in the game (performing actions relevant to the quest objective), their contributions can be recorded.
    *   This might happen automatically via integrated systems or require explicit calls (e.g., by an approved contract or the character owner).
    *   The system tracks the total contribution for the team.
    *   See: [`recordContribution` in SocialQuest API](./../api-reference/quest.md#recordcontribution)
4.  **Completion & Rewards:** Once the team's total contribution reaches the quest's target value within the time limit:
    *   The quest is marked complete for the team.
    *   A base reward (game tokens) is calculated and distributed among all members.
    *   A bonus reward may be given to the top contributor.
    *   Team members might receive an increased chance for item drops via the Item Drop system.
    *   See: [`completeTeamQuest` (Internal Logic) & Events in SocialQuest API](./../api-reference/quest.md#completeteamquest-internal)

### Key Aspects

-   **Temporary Teams:** Teams are formed *per quest instance*. They aren't persistent guilds.
-   **Shared Goal:** Success depends on the collective effort of the team reaching the target.
-   **Shared Rewards:** Rewards are typically split, incentivizing cooperation.

## 🤝 Referral Quests

Help the realm flourish by inviting new adventurers! The Referral Quest system rewards both the referrer and the new player (referree) when the new player achieves certain milestones.

### How Referrals Work

1.  **Quest Definition:** Referral Quest templates are created (by admins) defining the rewards for both the referrer and the referree, the milestone the referree must reach (e.g., character level), and the time limit.
    *   See: [`createReferralQuest` in SocialQuest API](./../api-reference/quest.md#createreferralquest)
2.  **Registration:** An existing player (the referrer) can register a referral link with a new player (the referree).
    *   This is done by providing the `characterId` for both the referrer and the referree.
    *   A character cannot be referred multiple times for the same quest.
    *   See: [`registerReferral` in SocialQuest API](./../api-reference/quest.md#registerreferral)
3.  **Milestone Achievement:** The referree plays the game. When they reach the required milestone (e.g., level) defined in the `ReferralQuest`:
    *   A system (likely needing approval to check character state) triggers the completion check.
    *   See: [`completeReferralQuest` in SocialQuest API](./../api-reference/quest.md#completereferralquest)
4.  **Completion & Rewards:** If the milestone is reached within the time limit:
    *   The referral is marked complete.
    *   Both the referrer and the referree automatically receive their defined token rewards.

### Key Aspects

-   **Incentivized Growth:** Rewards players for bringing active new users into the game.
-   **Milestone-Based:** Rewards are tied to the new player actually engaging with the game and reaching goals.

---

*Forge alliances, conquer challenges together, and help our community thrive!* ✨ 