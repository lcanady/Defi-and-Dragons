// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Character.sol";
import "../src/Equipment.sol";
import "../src/GameToken.sol";
import "../src/Quest.sol";
import "../src/ItemDrop.sol";

contract DeployScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        bytes32 vrfKeyHash = vm.envBytes32("VRF_KEY_HASH");
        address vrfCoordinator = vm.envAddress("VRF_COORDINATOR");
        uint64 vrfSubscriptionId = uint64(vm.envUint("VRF_SUBSCRIPTION_ID"));

        vm.startBroadcast(deployerPrivateKey);

        // Deploy core contracts
        Equipment equipment = new Equipment();
        Character character = new Character(address(equipment));
        GameToken gameToken = new GameToken();

        // Deploy and set up ItemDrop contract
        ItemDrop itemDrop = new ItemDrop(
            vrfCoordinator,
            address(equipment),
            vrfKeyHash,
            vrfSubscriptionId
        );

        // Set up contract relationships
        equipment.setCharacterContract(address(character));

        // Deploy and initialize Quest contract
        Quest quest = new Quest(address(character));
        quest.initialize(address(gameToken));
        gameToken.setQuestContract(address(quest), true);

        // Set up initial drop tables
        ItemDrop.DropEntry[] memory commonDrops = new ItemDrop.DropEntry[](3);
        commonDrops[0] = ItemDrop.DropEntry({equipmentId: 1, weight: 700}); // Common item: 70%
        commonDrops[1] = ItemDrop.DropEntry({equipmentId: 2, weight: 250}); // Uncommon item: 25%
        commonDrops[2] = ItemDrop.DropEntry({equipmentId: 3, weight: 50});  // Rare item: 5%
        
        itemDrop.createDropTable(1, "Common Drop Table", commonDrops);

        vm.stopBroadcast();

        console.log("Deployment complete!");
        console.log("Equipment:", address(equipment));
        console.log("Character:", address(character));
        console.log("GameToken:", address(gameToken));
        console.log("Quest:", address(quest));
        console.log("ItemDrop:", address(itemDrop));
    }
}
