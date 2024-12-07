// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./GameToken.sol";
import "./Equipment.sol";

contract Marketplace is Ownable, ERC1155Holder {
    GameToken public gameToken;
    Equipment public equipment;

    // Fee configuration
    uint256 public feePercentage = 500; // 5% (base 10000)
    address public feeCollector;

    // Listing structure
    struct Listing {
        address seller;
        uint256 equipmentId;
        uint256 amount;
        uint256 pricePerUnit;
        bool isActive;
    }

    // Mapping from listing ID to listing data
    mapping(uint256 => Listing) public listings;
    
    // Counter for creating new listings
    uint256 private _nextListingId = 1;

    // Events
    event ListingCreated(
        uint256 indexed listingId,
        address indexed seller,
        uint256 indexed equipmentId,
        uint256 amount,
        uint256 pricePerUnit
    );
    event ListingCancelled(uint256 indexed listingId);
    event ListingPurchased(
        uint256 indexed listingId,
        address indexed buyer,
        uint256 indexed equipmentId,
        uint256 amount,
        uint256 totalPrice
    );
    event FeeUpdated(uint256 oldFee, uint256 newFee);
    event FeeCollectorUpdated(address oldCollector, address newCollector);

    constructor(
        address _gameToken,
        address _equipment,
        address _feeCollector
    ) Ownable(msg.sender) {
        gameToken = GameToken(_gameToken);
        equipment = Equipment(_equipment);
        feeCollector = _feeCollector;
    }

    /**
     * @dev Create a new listing
     * @param equipmentId Equipment type ID
     * @param amount Amount of equipment to sell
     * @param pricePerUnit Price per unit in game tokens
     */
    function createListing(
        uint256 equipmentId,
        uint256 amount,
        uint256 pricePerUnit
    ) public returns (uint256) {
        require(amount > 0, "Amount must be positive");
        require(pricePerUnit > 0, "Price must be positive");
        require(
            equipment.balanceOf(msg.sender, equipmentId) >= amount,
            "Insufficient equipment balance"
        );

        uint256 listingId = _nextListingId++;

        listings[listingId] = Listing({
            seller: msg.sender,
            equipmentId: equipmentId,
            amount: amount,
            pricePerUnit: pricePerUnit,
            isActive: true
        });

        // Transfer equipment to marketplace contract
        equipment.safeTransferFrom(msg.sender, address(this), equipmentId, amount, "");

        emit ListingCreated(listingId, msg.sender, equipmentId, amount, pricePerUnit);
        return listingId;
    }

    /**
     * @dev Cancel an active listing
     * @param listingId Listing ID
     */
    function cancelListing(uint256 listingId) public {
        Listing storage listing = listings[listingId];
        require(listing.isActive, "Listing not active");
        require(listing.seller == msg.sender, "Not the seller");

        listing.isActive = false;

        // Return equipment to seller
        equipment.safeTransferFrom(
            address(this),
            msg.sender,
            listing.equipmentId,
            listing.amount,
            ""
        );

        emit ListingCancelled(listingId);
    }

    /**
     * @dev Purchase items from a listing
     * @param listingId Listing ID
     * @param amount Amount to purchase
     */
    function purchase(uint256 listingId, uint256 amount) public {
        Listing storage listing = listings[listingId];
        require(listing.isActive, "Listing not active");
        require(amount > 0 && amount <= listing.amount, "Invalid amount");

        uint256 totalPrice = amount * listing.pricePerUnit;
        uint256 feeAmount = (totalPrice * feePercentage) / 10000;
        uint256 sellerAmount = totalPrice - feeAmount;

        // Transfer payment from buyer to seller and fee collector
        gameToken.transferFrom(msg.sender, listing.seller, sellerAmount);
        if (feeAmount > 0) {
            gameToken.transferFrom(msg.sender, feeCollector, feeAmount);
        }

        // Transfer equipment to buyer
        equipment.safeTransferFrom(
            address(this),
            msg.sender,
            listing.equipmentId,
            amount,
            ""
        );

        // Update or close listing
        listing.amount -= amount;
        if (listing.amount == 0) {
            listing.isActive = false;
        }

        emit ListingPurchased(listingId, msg.sender, listing.equipmentId, amount, totalPrice);
    }

    /**
     * @dev Update marketplace fee percentage
     * @param newFeePercentage New fee percentage (base 10000)
     */
    function setFeePercentage(uint256 newFeePercentage) public onlyOwner {
        require(newFeePercentage <= 1000, "Fee too high"); // Max 10%
        emit FeeUpdated(feePercentage, newFeePercentage);
        feePercentage = newFeePercentage;
    }

    /**
     * @dev Update fee collector address
     * @param newFeeCollector New fee collector address
     */
    function setFeeCollector(address newFeeCollector) public onlyOwner {
        require(newFeeCollector != address(0), "Invalid address");
        emit FeeCollectorUpdated(feeCollector, newFeeCollector);
        feeCollector = newFeeCollector;
    }

    /**
     * @dev Get listing information
     * @param listingId Listing ID
     */
    function getListing(uint256 listingId) public view returns (Listing memory) {
        return listings[listingId];
    }
} 