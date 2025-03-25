// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Character.sol";
import "../src/Equipment.sol";
import "../src/GameToken.sol";
import "../src/Quest.sol";
import "../src/ItemDrop.sol";
import "../src/Marketplace.sol";
import "../src/ProvableRandom.sol";
import "../src/CombatQuest.sol";
import "../src/CombatAbilities.sol";

contract DeployLocal is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy core contracts
        Equipment equipment = new Equipment();
        ProvableRandom random = new ProvableRandom();
        Character character = new Character(address(equipment), address(random));
        GameToken gameToken = new GameToken();

        // Deploy ItemDrop
        ItemDrop itemDrop = new ItemDrop();
        itemDrop.initialize(address(equipment));

        // Deploy CombatAbilities
        CombatAbilities abilities = new CombatAbilities(deployer);
        abilities.transferOwnership(deployer);

        // Deploy CombatQuest with ItemDrop
        CombatQuest combatQuest = new CombatQuest(
            address(character),
            address(gameToken),
            address(abilities),
            address(itemDrop),
            deployer // Set deployer as initial owner
        );

        // Deploy and initialize Quest
        Quest quest = new Quest(address(character));
        quest.initialize(address(gameToken));

        // Deploy Marketplace
        Marketplace marketplace = new Marketplace(
            address(gameToken),
            address(equipment),
            deployer // Use deployer as fee collector for local testing
        );

        // Setup permissions
        bytes32 MINTER_ROLE = gameToken.MINTER_ROLE();
        gameToken.grantRole(MINTER_ROLE, address(quest));
        gameToken.grantRole(MINTER_ROLE, address(combatQuest));

        bytes32 EQUIPMENT_MINTER_ROLE = equipment.MINTER_ROLE();
        equipment.grantRole(EQUIPMENT_MINTER_ROLE, address(itemDrop));

        marketplace.updateListingFee(100);

        vm.stopBroadcast();

        // Save deployment info to file
        string memory deployInfo = string(
            abi.encodePacked(
                "EQUIPMENT_ADDRESS=",
                vm.toString(address(equipment)),
                "\n",
                "CHARACTER_ADDRESS=",
                vm.toString(address(character)),
                "\n",
                "GAME_TOKEN_ADDRESS=",
                vm.toString(address(gameToken)),
                "\n",
                "QUEST_ADDRESS=",
                vm.toString(address(quest)),
                "\n",
                "ITEM_DROP_ADDRESS=",
                vm.toString(address(itemDrop)),
                "\n",
                "MARKETPLACE_ADDRESS=",
                vm.toString(address(marketplace))
            )
        );
        vm.writeFile(".env.anvil", deployInfo);
    }
}
