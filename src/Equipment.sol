// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IEquipment.sol";
import "./interfaces/ICharacter.sol";
import "./interfaces/Types.sol";

contract Equipment is ERC1155, Ownable, IEquipment {
    ICharacter public character;

    // Override balanceOf from both ERC1155 and IEquipment
    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override(ERC1155, IEquipment)
        returns (uint256)
    {
        return super.balanceOf(account, id);
    }

    // Mapping from equipment ID to its stats
    mapping(uint256 => Types.EquipmentStats) public equipmentStats;

    // Mapping from equipment ID to its special abilities
    mapping(uint256 => Types.SpecialAbility[]) public equipmentAbilities;

    // Mapping to track ability cooldowns (characterId => equipmentId => abilityIndex => lastUse)
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) public abilityCooldowns;

    // Events
    event EquipmentCreated(uint256 indexed equipmentId, string name, Types.EquipmentStats stats);
    event SpecialAbilityAdded(uint256 indexed equipmentId, string abilityName);
    event SpecialAbilityTriggered(uint256 indexed characterId, uint256 indexed equipmentId, string abilityName);

    constructor() ERC1155("https://game.example/api/item/{id}.json") Ownable(msg.sender) { }

    function setCharacterContract(address characterContract) external onlyOwner {
        character = ICharacter(characterContract);
    }

    function createEquipment(
        uint256 equipmentId,
        string memory name,
        string memory description,
        uint8 strengthBonus,
        uint8 agilityBonus,
        uint8 magicBonus
    ) external onlyOwner {
        require(!equipmentStats[equipmentId].isActive, "Equipment ID already exists");

        equipmentStats[equipmentId] = Types.EquipmentStats({
            strengthBonus: strengthBonus,
            agilityBonus: agilityBonus,
            magicBonus: magicBonus,
            isActive: true,
            name: name,
            description: description
        });

        emit EquipmentCreated(equipmentId, name, equipmentStats[equipmentId]);
    }

    function addSpecialAbility(
        uint256 equipmentId,
        string memory name,
        string memory description,
        Types.TriggerCondition triggerCondition,
        uint256 triggerValue,
        Types.EffectType effectType,
        uint256 effectValue,
        uint256 cooldown
    ) external onlyOwner {
        require(equipmentStats[equipmentId].isActive, "Equipment does not exist");

        Types.SpecialAbility memory ability = Types.SpecialAbility({
            name: name,
            description: description,
            triggerCondition: triggerCondition,
            triggerValue: triggerValue,
            effectType: effectType,
            effectValue: effectValue,
            cooldown: cooldown
        });

        equipmentAbilities[equipmentId].push(ability);
        emit SpecialAbilityAdded(equipmentId, name);
    }

    function getEquipmentStats(uint256 equipmentId) external view override returns (Types.EquipmentStats memory) {
        require(equipmentStats[equipmentId].isActive, "Equipment does not exist");
        return equipmentStats[equipmentId];
    }

    function getSpecialAbility(uint256 equipmentId, uint256 abilityIndex)
        external
        view
        override
        returns (Types.SpecialAbility memory)
    {
        require(equipmentStats[equipmentId].isActive, "Equipment does not exist");
        require(abilityIndex < equipmentAbilities[equipmentId].length, "Invalid ability index");
        return equipmentAbilities[equipmentId][abilityIndex];
    }

    function getSpecialAbilities(uint256 equipmentId) external view override returns (Types.SpecialAbility[] memory) {
        require(equipmentStats[equipmentId].isActive, "Equipment does not exist");
        return equipmentAbilities[equipmentId];
    }

    function checkTriggerCondition(uint256 characterId, uint256 equipmentId, uint256 abilityIndex, uint256 currentRound)
        external
        view
        override
        returns (bool)
    {
        require(equipmentStats[equipmentId].isActive, "Equipment does not exist");
        Types.SpecialAbility memory ability = equipmentAbilities[equipmentId][abilityIndex];

        // Check cooldown
        if (currentRound - abilityCooldowns[characterId][equipmentId][abilityIndex] < ability.cooldown) {
            return false;
        }

        return true;
    }

    function calculateEquipmentBonus(uint256 characterId)
        external
        view
        override
        returns (uint8 strengthBonus, uint8 agilityBonus, uint8 magicBonus)
    {
        (, Types.EquipmentSlots memory equipped,) = character.getCharacter(characterId);

        // Add weapon bonuses
        if (equipped.weaponId != 0) {
            Types.EquipmentStats memory weapon = equipmentStats[equipped.weaponId];
            strengthBonus += weapon.strengthBonus;
            agilityBonus += weapon.agilityBonus;
            magicBonus += weapon.magicBonus;
        }

        // Add armor bonuses
        if (equipped.armorId != 0) {
            Types.EquipmentStats memory armor = equipmentStats[equipped.armorId];
            strengthBonus += armor.strengthBonus;
            agilityBonus += armor.agilityBonus;
            magicBonus += armor.magicBonus;
        }
    }

    function updateAbilityCooldown(uint256 characterId, uint256 equipmentId, uint256 abilityIndex, uint256 currentRound)
        external
        override
    {
        require(msg.sender == address(character), "Only Character contract can update cooldowns");
        require(abilityIndex < equipmentAbilities[equipmentId].length, "Invalid ability index");

        abilityCooldowns[characterId][equipmentId][abilityIndex] = currentRound;
    }

    function mint(address to, uint256 id, uint256 amount, bytes memory data) public onlyOwner {
        require(equipmentStats[id].isActive, "Equipment does not exist");
        _mint(to, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < ids.length; i++) {
            require(equipmentStats[ids[i]].isActive, "Equipment does not exist");
        }
        _mintBatch(to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
