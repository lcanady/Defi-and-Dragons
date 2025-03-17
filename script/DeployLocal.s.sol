// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Character.sol";
import "../src/Equipment.sol";
import "../src/GameToken.sol";
import "../src/Quest.sol";
import "../src/ItemDrop.sol";
import "../src/Marketplace.sol";
import "../src/test/MockVRFCoordinator.sol";

contract DeployLocal is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy mock VRF coordinator for local testing
        MockVRFCoordinator mockVrf = new MockVRFCoordinator();
        bytes32 keyHash = keccak256("MOCK_KEY_HASH");
        uint64 subId = mockVrf.createSubscription();
        mockVrf.fundSubscription(subId, 100 ether);

        // Deploy core contracts
        Equipment equipment = new Equipment();
        Character character = new Character(address(equipment));
        GameToken gameToken = new GameToken();

        // Deploy ItemDrop with mock VRF
        ItemDrop itemDrop = new ItemDrop(address(mockVrf), subId, keyHash, 200_000, 1, 1);
        itemDrop.initialize(address(equipment));

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

        bytes32 EQUIPMENT_MINTER_ROLE = equipment.MINTER_ROLE();
        equipment.grantRole(EQUIPMENT_MINTER_ROLE, address(itemDrop));

        marketplace.updateListingFee(100);

        // Add consumer to VRF subscription
        mockVrf.addConsumer(subId, address(itemDrop));

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
                vm.toString(address(marketplace)),
                "\n",
                "VRF_COORDINATOR_ADDRESS=",
                vm.toString(address(mockVrf))
            )
        );
        vm.writeFile(".env.anvil", deployInfo);
    }
}
