// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface Types {
    enum Alignment {
        STRENGTH,
        AGILITY,
        MAGIC
    }
    enum TriggerCondition {
        NONE,
        ON_LOW_HEALTH,
        ON_HIGH_DAMAGE,
        ON_CONSECUTIVE_HITS
    }
    enum EffectType {
        NONE,
        DAMAGE_BOOST,
        HEALING_BOOST,
        DEFENSE_BOOST
    }

    struct Stats {
        uint256 strength;
        uint256 agility;
        uint256 magic;
    }

    struct CharacterState {
        uint256 health;
        uint256 consecutiveHits;
        uint256 damageReceived;
        uint256 roundsParticipated;
        Alignment alignment;
        uint256 level;
        uint256 class;
    }

    struct EquipmentSlots {
        uint256 weaponId;
        uint256 armorId;
    }

    struct EquipmentStats {
        uint8 strengthBonus;
        uint8 agilityBonus;
        uint8 magicBonus;
        bool isActive;
        Alignment statAffinity;
        string name;
        string description;
    }

    struct SpecialAbility {
        string name;
        string description;
        TriggerCondition triggerCondition;
        uint256 triggerValue;
        EffectType effectType;
        uint256 effectValue;
        uint256 cooldown;
    }

    struct AttributeBonuses {
        uint256 yieldBoost;
        uint256 dropRateBoost;
    }
}
