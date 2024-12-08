// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./interfaces/IGameToken.sol";

contract Marketplace is Ownable, ReentrancyGuard, ERC1155Holder {
    IGameToken public immutable gameToken;
    IERC1155 public immutable equipment;
    address public feeCollector;
    uint256 public constant FEE_DENOMINATOR = 10_000;
    uint256 public listingFee = 100; // 1% fee

    struct Listing {
        address seller;
        uint256 price;
        uint256 amount;
        bool active;
    }

    // equipmentId => listingId => Listing
    mapping(uint256 => mapping(uint256 => Listing)) public listings;
    mapping(uint256 => uint256) public nextListingId;

    event ItemListed(
        uint256 indexed equipmentId, uint256 indexed listingId, address indexed seller, uint256 price, uint256 amount
    );
    event ItemPurchased(
        uint256 indexed equipmentId, uint256 indexed listingId, address indexed buyer, uint256 price, uint256 amount
    );
    event ListingCancelled(uint256 indexed equipmentId, uint256 indexed listingId);
    event ListingFeeUpdated(uint256 newFee);
    event FeeCollectorUpdated(address newCollector);

    constructor(address _gameToken, address _equipment, address _feeCollector) {
        _transferOwnership(msg.sender);
        gameToken = IGameToken(_gameToken);
        equipment = IERC1155(_equipment);
        feeCollector = _feeCollector;
    }

    function listItem(uint256 equipmentId, uint256 price, uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(price > 0, "Price must be greater than 0");
        require(equipment.balanceOf(msg.sender, equipmentId) >= amount, "Insufficient equipment balance");

        uint256 listingId = nextListingId[equipmentId]++;
        listings[equipmentId][listingId] = Listing({ seller: msg.sender, price: price, amount: amount, active: true });

        equipment.safeTransferFrom(msg.sender, address(this), equipmentId, amount, "");

        emit ItemListed(equipmentId, listingId, msg.sender, price, amount);
    }

    function purchaseItem(uint256 equipmentId, uint256 listingId, uint256 amount) external nonReentrant {
        Listing storage listing = listings[equipmentId][listingId];
        require(listing.active, "Listing is not active");
        require(amount > 0 && amount <= listing.amount, "Invalid amount");

        uint256 totalPrice = listing.price * amount;
        uint256 fee = (totalPrice * listingFee) / FEE_DENOMINATOR;
        uint256 sellerAmount = totalPrice - fee;

        // Transfer payment
        gameToken.transferFrom(msg.sender, listing.seller, sellerAmount);
        if (fee > 0) {
            gameToken.transferFrom(msg.sender, feeCollector, fee);
        }

        // Transfer equipment
        equipment.safeTransferFrom(address(this), msg.sender, equipmentId, amount, "");

        // Update listing
        listing.amount -= amount;
        if (listing.amount == 0) {
            listing.active = false;
        }

        emit ItemPurchased(equipmentId, listingId, msg.sender, listing.price, amount);
    }

    function cancelListing(uint256 equipmentId, uint256 listingId) external nonReentrant {
        Listing storage listing = listings[equipmentId][listingId];
        require(listing.active, "Listing is not active");
        require(listing.seller == msg.sender, "Not the seller");

        listing.active = false;
        equipment.safeTransferFrom(address(this), msg.sender, equipmentId, listing.amount, "");

        emit ListingCancelled(equipmentId, listingId);
    }

    function updateListingFee(uint256 newFee) external onlyOwner {
        require(newFee <= 1000, "Fee too high"); // Max 10%
        listingFee = newFee;
        emit ListingFeeUpdated(newFee);
    }

    function updateFeeCollector(address newCollector) external onlyOwner {
        require(newCollector != address(0), "Invalid address");
        feeCollector = newCollector;
        emit FeeCollectorUpdated(newCollector);
    }

    function getListing(uint256 equipmentId, uint256 listingId)
        external
        view
        returns (address seller, uint256 price, uint256 amount, bool active)
    {
        Listing storage listing = listings[equipmentId][listingId];
        return (listing.seller, listing.price, listing.amount, listing.active);
    }
}
