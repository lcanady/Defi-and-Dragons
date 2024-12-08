// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/GameToken.sol";

contract GameTokenTest is Test {
    GameToken public gameToken;
    address public owner;
    address public questContract;
    address public marketplaceContract;
    address public user;

    function setUp() public {
        owner = address(this);
        questContract = address(0x1);
        marketplaceContract = address(0x2);
        user = address(0x3);

        gameToken = new GameToken();
    }

    function testMintAsOwner() public {
        uint256 amount = 100 * 10 ** 18;
        gameToken.mint(user, amount);
        assertEq(gameToken.balanceOf(user), amount);
    }

    function testMintAsQuestContract() public {
        uint256 amount = 100 * 10 ** 18;
        gameToken.setQuestContract(questContract, true);

        vm.prank(questContract);
        gameToken.mint(user, amount);
        assertEq(gameToken.balanceOf(user), amount);
    }

    function testFailMintAsUnauthorized() public {
        uint256 amount = 100 * 10 ** 18;
        vm.prank(user);
        gameToken.mint(user, amount);
    }

    function testBurnAsOwner() public {
        uint256 amount = 100 * 10 ** 18;
        gameToken.mint(user, amount);
        gameToken.burn(user, amount);
        assertEq(gameToken.balanceOf(user), 0);
    }

    function testBurnAsMarketplace() public {
        uint256 amount = 100 * 10 ** 18;
        gameToken.mint(user, amount);
        gameToken.setMarketplaceContract(marketplaceContract, true);

        vm.prank(marketplaceContract);
        gameToken.burn(user, amount);
        assertEq(gameToken.balanceOf(user), 0);
    }

    function testFailBurnAsUnauthorized() public {
        uint256 amount = 100 * 10 ** 18;
        gameToken.mint(user, amount);

        vm.prank(user);
        gameToken.burn(user, amount);
    }

    function testSetQuestContract() public {
        gameToken.setQuestContract(questContract, true);
        assertTrue(gameToken.questContracts(questContract));

        gameToken.setQuestContract(questContract, false);
        assertFalse(gameToken.questContracts(questContract));
    }

    function testSetMarketplaceContract() public {
        gameToken.setMarketplaceContract(marketplaceContract, true);
        assertTrue(gameToken.marketplaceContracts(marketplaceContract));

        gameToken.setMarketplaceContract(marketplaceContract, false);
        assertFalse(gameToken.marketplaceContracts(marketplaceContract));
    }

    function testFailSetQuestContractAsNonOwner() public {
        vm.prank(user);
        gameToken.setQuestContract(questContract, true);
    }

    function testFailSetMarketplaceContractAsNonOwner() public {
        vm.prank(user);
        gameToken.setMarketplaceContract(marketplaceContract, true);
    }
}
