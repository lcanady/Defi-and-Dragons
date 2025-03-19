// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import { Equipment } from "../../src/Equipment.sol";

contract TestHelper is Test {
    function setupEquipment(Equipment equipment, address characterContract) public {
        equipment.setCharacterContract(characterContract);
        // Create test equipment
        equipment.createEquipment(
            "Test Weapon",
            "A test weapon",
            5, // strength bonus
            0, // agility bonus
            0 // magic bonus
        );

        equipment.createEquipment(
            "Test Armor",
            "A test armor",
            0, // strength bonus
            5, // agility bonus
            0 // magic bonus
        );
    }

    function findRequestIdFromLogs(Vm.Log[] memory entries) public pure returns (uint256 requestId, bool found) {
        for (uint256 i = 0; i < entries.length; i++) {
            // Check for RandomWordsRequested event from VRFCoordinatorV2Mock
            if (
                entries[i].topics[0]
                    == keccak256("RandomWordsRequested(bytes32,uint256,uint256,uint64,uint16,uint32,uint32,address)")
            ) {
                requestId = uint256(entries[i].topics[2]); // requestId is the second topic
                found = true;
                break;
            }
        }
    }

    function _mintTestEquipment(Equipment equipment, address to, uint256[] memory itemIds, uint256[] memory amounts)
        internal
    {
        require(itemIds.length == amounts.length, "Array length mismatch");
        for (uint256 i = 0; i < itemIds.length; i++) {
            equipment.mint(to, itemIds[i], amounts[i], "");
        }
    }

    function _checkEquipmentBalances(Equipment equipment, address owner, uint256[] memory itemIds)
        internal
        view
        returns (uint256[] memory)
    {
        uint256[] memory balances = new uint256[](itemIds.length);
        for (uint256 i = 0; i < itemIds.length; i++) {
            balances[i] = equipment.balanceOf(owner, itemIds[i]);
        }
        return balances;
    }
}
