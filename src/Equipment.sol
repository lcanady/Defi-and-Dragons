// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/Types.sol";
import "./interfaces/IEquipment.sol";
import "./interfaces/Errors.sol";

contract Equipment is ERC1155, Ownable, IEquipment {
    mapping(uint256 => Types.EquipmentStats) public equipmentStats;
    mapping(uint256 => Types.SpecialAbility[]) public specialAbilities;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) public abilityCooldowns;

    address private _characterContract;

    constructor() ERC1155("https://game.example/api/item/{id}.json") {
        _transferOwnership(msg.sender);
    }

    modifier onlyCharacterContract() {
        require(msg.sender == _characterContract, "Only character contract");
        _;
    }

    function setCharacterContract(address characterContract) external onlyOwner {
        require(characterContract != address(0), "Invalid character contract");
        _characterContract = characterContract;
    }

    function createEquipment(
        uint256 equipmentId,
        string memory name,
        string memory description,
        uint8 strengthBonus,
        uint8 agilityBonus,
        uint8 magicBonus
    ) external onlyOwner {
        Types.EquipmentStats memory stats = Types.EquipmentStats({
            strengthBonus: strengthBonus,
            agilityBonus: agilityBonus,
            magicBonus: magicBonus,
            isActive: true,
            name: name,
            description: description
        });
        equipmentStats[equipmentId] = stats;
    }

    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override(ERC1155, IEquipment)
        returns (uint256)
    {
        return super.balanceOf(account, id);
    }

    function mint(address to, uint256 id, uint256 amount, bytes memory data) external {
        require(msg.sender == owner() || msg.sender == _characterContract, "Not authorized to mint");
        _mint(to, id, amount, data);
    }

    function setEquipmentStats(uint256 equipmentId, Types.EquipmentStats memory stats) external onlyOwner {
        equipmentStats[equipmentId] = stats;
    }

    function setSpecialAbilities(uint256 equipmentId, Types.SpecialAbility[] memory abilities) external onlyOwner {
        delete specialAbilities[equipmentId];
        for (uint256 i = 0; i < abilities.length; i++) {
            specialAbilities[equipmentId].push(abilities[i]);
        }
    }

    function getEquipmentStats(uint256 equipmentId) external view returns (Types.EquipmentStats memory) {
        return equipmentStats[equipmentId];
    }

    function getSpecialAbility(uint256 equipmentId, uint256 abilityIndex)
        external
        view
        returns (Types.SpecialAbility memory)
    {
        require(abilityIndex < specialAbilities[equipmentId].length, "Invalid ability index");
        return specialAbilities[equipmentId][abilityIndex];
    }

    function getSpecialAbilities(uint256 equipmentId) external view returns (Types.SpecialAbility[] memory) {
        return specialAbilities[equipmentId];
    }

    function updateAbilityCooldown(uint256 characterId, uint256 equipmentId, uint256 abilityIndex, uint256 currentRound)
        external
        onlyCharacterContract
    {
        require(abilityIndex < specialAbilities[equipmentId].length, "Invalid ability index");
        abilityCooldowns[characterId][equipmentId][abilityIndex] = currentRound;
    }

    function checkTriggerCondition(uint256 characterId, uint256 equipmentId, uint256 abilityIndex, uint256 currentRound)
        external
        view
        returns (bool)
    {
        require(abilityIndex < specialAbilities[equipmentId].length, "Invalid ability index");
        Types.SpecialAbility memory ability = specialAbilities[equipmentId][abilityIndex];
        uint256 lastUsed = abilityCooldowns[characterId][equipmentId][abilityIndex];
        return currentRound >= lastUsed + ability.cooldown;
    }

    function calculateEquipmentBonus(uint256 characterId)
        external
        view
        returns (uint8 strengthBonus, uint8 agilityBonus, uint8 magicBonus)
    {
        // This is a placeholder implementation
        // In a real game, you would track equipped items and sum their bonuses
        return (0, 0, 0);
    }
}
