// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Character related errors
error NotCharacterOwner();
error CharacterNotFound();
error InvalidStatTotal();
error InvalidStatValue();

// Equipment related errors
error NotWeaponOwner();
error NotArmorOwner();
error NotCharacterContract();
error InvalidCharacterContract();
error InvalidItemDropContract();
error EquipmentNotFound();
error EquipmentNotActive();
error InvalidAbilityIndex();
error NoEquipmentBonuses();

// Quest related errors
error QuestNotExists();
error QuestAlreadyActive();
error QuestNotActive();
error RaidFull();
error RaidRequiresParty();
error QuestDoesNotSupportParty();
error PartyNotActive();
error NotPartyOwner();
error PartyTooLarge();
error WalletAlreadyParticipating();
error NotAllCharactersOwned();
error CharacterOnCooldown();
error InsufficientStrength();
error InsufficientAgility();
error InsufficientMagic();
error NoPartiesInRaid();
error NotRaidParticipant();
error AlreadyInitialized();
error NoObjectives();
error BonusTooHigh();
error InvalidRaidSize();
error RaidsMustSupportParties();

// Party related errors
error PartyFull();
error CharacterInParty();
error CharacterNotInParty();
error InvalidPartySize();
error EmptyParty();

// Combat related errors
error CombatOnCooldown();
error NotActiveBoss();
error MissingRequiredItem();
error NotOwner();
error FightNotActive();
error BossAlreadyDefeated();
error InvalidMonster();
error HuntNotActive();
error HuntAlreadyCompleted();
error InvalidHunt();

// Item drop related errors
error NotInitialized();
error RequestAlreadyFulfilled();

// Common errors
error NotAuthorized();
error ZeroAddress();
