// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IDnDBase {
    enum Alignment {
        NONE,
        STRENGTH,
        AGILITY,
        MAGIC
    }

    struct Stats {
        uint8 strength;
        uint8 agility;
        uint8 magic;
    }

    struct CharacterState {
        uint256 health;
        uint256 consecutiveHits;
        uint256 damageReceived;
        uint256 roundsParticipated;
        Alignment alignment;
    }

    struct EquipmentSlots {
        uint256 weaponId;
        uint256 armorId;
    }

    enum EffectType {
        NONE,
        DAMAGE_BOOST,
        HEALING_BOOST,
        DEFENSE_BOOST
    }

    struct EquipmentStats {
        uint8 strengthBonus;
        uint8 agilityBonus;
        uint8 magicBonus;
        bool isActive;
        string name;
        string description;
    }

    struct SpecialAbility {
        string name;
        EffectType effectType;
        uint256 effectValue;
        uint256 cooldown;
    }
}
