// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Character.sol";
import "../src/Equipment.sol";
import "../src/GameToken.sol";
import "../src/Quest.sol";

contract DeployScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy core contracts
        Equipment equipment = new Equipment();
        Character character = new Character(address(equipment));
        GameToken gameToken = new GameToken();

        // Set up contract relationships
        equipment.setCharacterContract(address(character));

        // Deploy and initialize Quest contract
        Quest quest = new Quest(address(character));
        quest.initialize(address(gameToken));
        gameToken.setQuestContract(address(quest), true);

        vm.stopBroadcast();
    }
}
