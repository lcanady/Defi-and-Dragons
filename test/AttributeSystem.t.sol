// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ProvableRandom} from "../src/ProvableRandom.sol";
import {ProvableRandomMock} from "./mocks/ProvableRandomMock.sol";
import {AttributeSystem} from "../src/AttributeSystem.sol";

contract AttributeSystemTest is Test {
    ProvableRandomMock public random;
    AttributeSystem public attributeSystem;
    address public user = address(1);
    bytes32 public context;

    function setUp() public {
        random = new ProvableRandomMock();
        attributeSystem = new AttributeSystem(address(random));
        context = bytes32(uint256(uint160(address(this))));
    }

    function testCalculateBonus() public {
        random.resetSeed(user, context);
        random.initializeSeed(user, context);

        // Mock random numbers for testing
        uint256[] memory numbers = new uint256[](3);
        numbers[0] = 5;
        numbers[1] = 10;
        numbers[2] = 15;

        vm.mockCall(
            address(random),
            abi.encodeWithSelector(bytes4(keccak256("generateNumbers(address,bytes32,uint256)")), user, context, 3),
            abi.encode(numbers)
        );

        // Add some providers
        attributeSystem.addProvider(address(1));
        attributeSystem.addProvider(address(2));
        attributeSystem.addProvider(address(3));

        // Calculate bonus for a character ID
        uint256 tokenId = 1;
        uint256 bonus = attributeSystem.calculateBonus(tokenId);

        // With 3 providers, each providing 2060 bonus points
        // Total bonus should be 6180
        assertEq(bonus, 6180, "Bonus calculation incorrect");
    }
}
