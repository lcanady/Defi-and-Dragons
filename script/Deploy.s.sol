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
            vrfSubscriptionId,
            vrfKeyHash,
            200_000, // callbackGasLimit
            3, // requestConfirmations
            1 // numWords
        );
        itemDrop.initialize(address(equipment));

        // Deploy and initialize Quest contract
        Quest quest = new Quest(address(character));
        quest.initialize(address(gameToken));

        vm.stopBroadcast();

        console.log("Deployment complete!");
        console.log("Equipment:", address(equipment));
        console.log("Character:", address(character));
        console.log("GameToken:", address(gameToken));
        console.log("Quest:", address(quest));
        console.log("ItemDrop:", address(itemDrop));
    }
}
