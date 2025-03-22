// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { ProvableRandom } from "../src/ProvableRandom.sol";

contract TestRandom is ProvableRandom {
    function exposedGenerateNumbers(uint256 count) external returns (uint256[] memory) {
        return generateNumbers(count);
    }

    function exposedInitializeSeed(bytes32 seed) external {
        initializeSeed(seed);
    }
}

contract ProvableRandomTest is Test {
    TestRandom public random;
    address public user1;
    address public user2;

    event NumbersGenerated(
        address indexed user,
        uint256[] numbers,
        bytes32 seed,
        uint256 nonce
    );

    function setUp() public {
        random = new TestRandom();
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
    }

    function testInitializeSeed() public {
        bytes32 seed = keccak256(abi.encodePacked("test seed"));
        vm.prank(user1);
        random.exposedInitializeSeed(seed);
        assertEq(random.getCurrentSeed(user1), seed, "Seed not set correctly");
    }

    function testCannotReinitializeSeed() public {
        bytes32 seed = keccak256(abi.encodePacked("test seed"));
        vm.startPrank(user1);
        random.exposedInitializeSeed(seed);
        vm.expectRevert("Seed already initialized");
        random.exposedInitializeSeed(seed);
        vm.stopPrank();
    }

    function testGenerateNumbers() public {
        bytes32 seed = keccak256(abi.encodePacked("test seed"));
        vm.startPrank(user1);
        random.exposedInitializeSeed(seed);
        
        uint256[] memory numbers = random.exposedGenerateNumbers(3);
        assertEq(numbers.length, 3, "Wrong number of random numbers generated");
        
        // Numbers should be different
        assertTrue(numbers[0] != numbers[1], "First two numbers are the same");
        assertTrue(numbers[1] != numbers[2], "Last two numbers are the same");
        assertTrue(numbers[0] != numbers[2], "First and last numbers are the same");
        vm.stopPrank();
    }

    function testGenerateNumbersRequiresSeed() public {
        vm.prank(user1);
        vm.expectRevert("Seed not initialized");
        random.exposedGenerateNumbers(1);
    }

    function testDifferentUsersGetDifferentNumbers() public {
        bytes32 seed1 = keccak256(abi.encodePacked("user1 seed"));
        bytes32 seed2 = keccak256(abi.encodePacked("user2 seed"));

        vm.prank(user1);
        random.exposedInitializeSeed(seed1);
        vm.prank(user2);
        random.exposedInitializeSeed(seed2);

        vm.prank(user1);
        uint256[] memory numbers1 = random.exposedGenerateNumbers(1);
        vm.prank(user2);
        uint256[] memory numbers2 = random.exposedGenerateNumbers(1);

        assertTrue(numbers1[0] != numbers2[0], "Users got the same random number");
    }

    function testVerifyNumbers() public {
        bytes32 seed = keccak256(abi.encodePacked("test seed"));
        vm.startPrank(user1);
        random.exposedInitializeSeed(seed);
        
        uint256[] memory numbers = random.exposedGenerateNumbers(3);
        assertTrue(random.verifyNumbers(numbers, seed, 1), "Numbers verification failed");
        vm.stopPrank();
    }

    function testVerifyNumbersWithWrongSeed() public {
        bytes32 seed = keccak256(abi.encodePacked("test seed"));
        bytes32 wrongSeed = keccak256(abi.encodePacked("wrong seed"));
        
        vm.startPrank(user1);
        random.exposedInitializeSeed(seed);
        uint256[] memory numbers = random.exposedGenerateNumbers(3);
        assertFalse(random.verifyNumbers(numbers, wrongSeed, 1), "Verification should fail with wrong seed");
        vm.stopPrank();
    }

    function testVerifyNumbersWithWrongNonce() public {
        bytes32 seed = keccak256(abi.encodePacked("test seed"));
        
        vm.startPrank(user1);
        random.exposedInitializeSeed(seed);
        uint256[] memory numbers = random.exposedGenerateNumbers(3);
        assertFalse(random.verifyNumbers(numbers, seed, 2), "Verification should fail with wrong nonce");
        vm.stopPrank();
    }

    function testEmitsEvent() public {
        bytes32 seed = keccak256(abi.encodePacked("test seed"));
        vm.startPrank(user1);
        random.exposedInitializeSeed(seed);
        
        vm.expectEmit(true, false, false, false);
        emit NumbersGenerated(user1, new uint256[](1), bytes32(0), 0);
        random.exposedGenerateNumbers(1);
        vm.stopPrank();
    }

    function testSequentialNumbersAreDifferent() public {
        bytes32 seed = keccak256(abi.encodePacked("test seed"));
        vm.startPrank(user1);
        random.exposedInitializeSeed(seed);
        
        uint256[] memory first = random.exposedGenerateNumbers(1);
        uint256[] memory second = random.exposedGenerateNumbers(1);
        assertTrue(first[0] != second[0], "Sequential numbers should be different");
        vm.stopPrank();
    }
} 