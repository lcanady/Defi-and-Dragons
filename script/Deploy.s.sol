// SPDX-License-Identifier: MIT
/* eslint-disable no-console */
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { GameToken } from "../src/GameToken.sol";
import { Equipment } from "../src/Equipment.sol";
import { Character } from "../src/Character.sol";
import { ProvableRandom } from "../src/ProvableRandom.sol";
import { ItemDrop } from "../src/ItemDrop.sol";
import { Quest } from "../src/Quest.sol";
import { Marketplace } from "../src/Marketplace.sol";
import { CombatQuest } from "../src/CombatQuest.sol";
import { CombatAbilities } from "../src/CombatAbilities.sol";
import { CombatDamageCalculator } from "../src/CombatDamageCalculator.sol";
import { Party } from "../src/Party.sol";

contract DeployScript is Script {
    function run() public {
        // Load environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address feeCollector = vm.envAddress("FEE_COLLECTOR");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy core contracts first that don't have dependencies
        GameToken gameToken = new GameToken();
        ProvableRandom random = new ProvableRandom();

        // Deploy Equipment with a temporary address for character
        Equipment equipment = new Equipment(address(0));

        // Now deploy Character with the real equipment address
        Character character = new Character(address(equipment), address(random));

        // Update Equipment with the real character address
        equipment.setCharacterContract(address(character));

        // Deploy remaining contracts that depend on the core contracts
        Party party = new Party(address(character));
        ItemDrop itemDrop = new ItemDrop(address(random));

        // Deploy quest contracts
        CombatQuest combatQuest = new CombatQuest(
            msg.sender,
            address(character),
            address(gameToken),
            address(0), // abilities
            address(itemDrop),
            address(0) // damageCalculator
        );
        CombatDamageCalculator calculator = new CombatDamageCalculator(address(character), address(equipment));

        // Deploy marketplace
        Marketplace marketplace = new Marketplace(address(gameToken), address(equipment), msg.sender);

        // Set up initial marketplace parameters
        marketplace.updateListingFee(100); // 1% fee

        vm.stopBroadcast();
    }
}
