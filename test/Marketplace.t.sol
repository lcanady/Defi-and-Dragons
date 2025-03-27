// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { Marketplace } from "../src/Marketplace.sol";
import { GameToken } from "../src/GameToken.sol";
import { MockEquipment } from "./mocks/MockEquipment.sol";

contract MarketplaceTest is Test {
    Marketplace public marketplace;
    GameToken public gameToken;
    MockEquipment public equipment;

    address public owner;
    address public seller;
    address public buyer;
    address public feeCollector;

    uint256 public constant INITIAL_BALANCE = 1000 ether;
    uint256 public constant EQUIPMENT_ID = 1;
    uint256 public constant AMOUNT = 5;
    uint256 public constant PRICE_PER_UNIT = 10 ether;

    function setUp() public {
        owner = address(this);
        seller = makeAddr("seller");
        buyer = makeAddr("buyer");
        feeCollector = makeAddr("feeCollector");

        // Deploy contracts
        gameToken = new GameToken();
        equipment = new MockEquipment(address(0));
        marketplace = new Marketplace(address(gameToken), address(equipment), feeCollector);

        // Setup initial balances
        gameToken.mint(buyer, INITIAL_BALANCE);
        equipment.mint(seller, EQUIPMENT_ID, AMOUNT, "");

        // Approve marketplace
        vm.prank(seller);
        equipment.setApprovalForAll(address(marketplace), true);
        vm.prank(buyer);
        gameToken.approve(address(marketplace), type(uint256).max);
    }

    function testListItem() public {
        vm.prank(seller);
        uint256 listingId = 0; // First listing for this equipment ID
        marketplace.listItem(EQUIPMENT_ID, PRICE_PER_UNIT, AMOUNT);

        (address listedSeller, uint256 price, uint256 amount, bool active) =
            marketplace.getListing(EQUIPMENT_ID, listingId);
        assertEq(listedSeller, seller);
        assertEq(price, PRICE_PER_UNIT);
        assertEq(amount, AMOUNT);
        assertTrue(active);
    }

    function testCancelListing() public {
        vm.startPrank(seller);
        uint256 listingId = 0; // First listing for this equipment ID
        marketplace.listItem(EQUIPMENT_ID, PRICE_PER_UNIT, AMOUNT);
        marketplace.cancelListing(EQUIPMENT_ID, listingId);
        vm.stopPrank();

        (,,, bool active) = marketplace.getListing(EQUIPMENT_ID, listingId);
        assertFalse(active);
        assertEq(equipment.balanceOf(seller, EQUIPMENT_ID), AMOUNT);
    }

    function testPurchase() public {
        // Create listing
        vm.prank(seller);
        uint256 listingId = 0; // First listing for this equipment ID
        marketplace.listItem(EQUIPMENT_ID, PRICE_PER_UNIT, AMOUNT);

        uint256 purchaseAmount = 2;
        uint256 totalPrice = purchaseAmount * PRICE_PER_UNIT;
        uint256 feeAmount = (totalPrice * marketplace.listingFee()) / marketplace.FEE_DENOMINATOR();
        uint256 sellerAmount = totalPrice - feeAmount;

        // Record balances before purchase
        uint256 buyerTokensBefore = gameToken.balanceOf(buyer);
        uint256 sellerTokensBefore = gameToken.balanceOf(seller);
        uint256 feeCollectorTokensBefore = gameToken.balanceOf(feeCollector);

        // Make purchase
        vm.prank(buyer);
        marketplace.purchaseItem(EQUIPMENT_ID, listingId, purchaseAmount);

        // Verify token transfers
        assertEq(gameToken.balanceOf(buyer), buyerTokensBefore - totalPrice);
        assertEq(gameToken.balanceOf(seller), sellerTokensBefore + sellerAmount);
        assertEq(gameToken.balanceOf(feeCollector), feeCollectorTokensBefore + feeAmount);

        // Verify equipment transfer
        assertEq(equipment.balanceOf(buyer, EQUIPMENT_ID), purchaseAmount);

        // Verify listing update
        (,, uint256 remainingAmount, bool active) = marketplace.getListing(EQUIPMENT_ID, listingId);
        assertEq(remainingAmount, AMOUNT - purchaseAmount);
        assertTrue(active);
    }

    function testPurchaseEntireListing() public {
        // Create listing
        vm.prank(seller);
        uint256 listingId = 0; // First listing for this equipment ID
        marketplace.listItem(EQUIPMENT_ID, PRICE_PER_UNIT, AMOUNT);

        // Purchase entire listing
        vm.prank(buyer);
        marketplace.purchaseItem(EQUIPMENT_ID, listingId, AMOUNT);

        // Verify listing is closed
        (,, uint256 remainingAmount, bool active) = marketplace.getListing(EQUIPMENT_ID, listingId);
        assertEq(remainingAmount, 0);
        assertFalse(active);
    }

    function testUpdateListingFee() public {
        uint256 newFee = 1000; // 10%
        marketplace.updateListingFee(newFee);
        assertEq(marketplace.listingFee(), newFee);
    }

    function testUpdateFeeCollector() public {
        address newFeeCollector = makeAddr("newFeeCollector");
        marketplace.updateFeeCollector(newFeeCollector);
        assertEq(marketplace.feeCollector(), newFeeCollector);
    }

    function testFailListItemInsufficientBalance() public {
        vm.prank(seller);
        marketplace.listItem(EQUIPMENT_ID, PRICE_PER_UNIT, AMOUNT + 1);
    }

    function testFailPurchaseInactiveListing() public {
        // Create and cancel listing
        vm.startPrank(seller);
        uint256 listingId = 0; // First listing for this equipment ID
        marketplace.listItem(EQUIPMENT_ID, PRICE_PER_UNIT, AMOUNT);
        marketplace.cancelListing(EQUIPMENT_ID, listingId);
        vm.stopPrank();

        // Attempt to purchase
        vm.prank(buyer);
        marketplace.purchaseItem(EQUIPMENT_ID, listingId, 1);
    }

    function testFailPurchaseInsufficientAmount() public {
        vm.prank(seller);
        uint256 listingId = 0; // First listing for this equipment ID
        marketplace.listItem(EQUIPMENT_ID, PRICE_PER_UNIT, AMOUNT);

        vm.prank(buyer);
        marketplace.purchaseItem(EQUIPMENT_ID, listingId, AMOUNT + 1);
    }
}
