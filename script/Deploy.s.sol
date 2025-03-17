// SPDX-License-Identifier: MIT
/* eslint-disable no-console */
pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { Character } from "../src/Character.sol";
import { Equipment } from "../src/Equipment.sol";
import { GameToken } from "../src/GameToken.sol";
import { Quest } from "../src/Quest.sol";
import { ItemDrop } from "../src/ItemDrop.sol";
import { Marketplace } from "../src/Marketplace.sol";

contract DeployScript is Script {
    function run() public {
        // Load environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        bytes32 vrfKeyHash = vm.envBytes32("VRF_KEY_HASH");
        address vrfCoordinator = vm.envAddress("VRF_COORDINATOR");
        uint64 vrfSubscriptionId = uint64(vm.envUint("VRF_SUBSCRIPTION_ID"));
        address feeCollector = vm.envAddress("FEE_COLLECTOR");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy core contracts
        Equipment equipment = new Equipment();
        Character character = new Character(address(equipment));
        GameToken gameToken = new GameToken();

        // Deploy and set up ItemDrop contract with VRF
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

        // Deploy Marketplace with proper configuration
        Marketplace marketplace = new Marketplace(address(gameToken), address(equipment), feeCollector);

        // Set up permissions and links between contracts

        // Authorize Quest contract to mint tokens
        gameToken.setQuestContract(address(quest), true);

        // Set up Equipment contract permissions
        equipment.setCharacterContract(address(character));
        equipment.setItemDrop(address(itemDrop));

        // Set up initial marketplace parameters
        marketplace.updateListingFee(100); // 1% fee

        vm.stopBroadcast();

        // Log deployed addresses
        console2.log("Deployment Summary:");
        console2.log("-----------------");
        console2.log("Equipment:", address(equipment));
        console2.log("Character:", address(character));
        console2.log("GameToken:", address(gameToken));
        console2.log("Quest:", address(quest));
        console2.log("ItemDrop:", address(itemDrop));
        console2.log("Marketplace:", address(marketplace));
        console2.log("\nPermissions Setup:");
        console2.log("-----------------");
        console2.log("Quest is authorized for GameToken:", gameToken.questContracts(address(quest)));
        console2.log("Character Contract set for Equipment:", address(character));
        console2.log("ItemDrop Contract set for Equipment:", address(itemDrop));
        console2.log("\nConfiguration:");
        console2.log("-----------------");
        console2.log("Marketplace Fee Collector:", marketplace.feeCollector());
        console2.log("Marketplace Listing Fee:", marketplace.listingFee());
    }
}
