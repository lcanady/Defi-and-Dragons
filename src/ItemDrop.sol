// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "./interfaces/Types.sol";
import "./interfaces/IEquipment.sol";

contract ItemDrop is VRFConsumerBaseV2, Ownable {
    VRFCoordinatorV2Interface public immutable vrfCoordinator;
    IEquipment public equipment;

    uint64 public subscriptionId;
    bytes32 public keyHash;
    uint32 public callbackGasLimit;
    uint16 public requestConfirmations;
    uint32 public numWords;

    struct DropRequest {
        address player;
        uint256 dropRateBonus;
        bool fulfilled;
    }

    mapping(uint256 => DropRequest) public dropRequests;
    mapping(uint256 => uint256[]) public requestToRandomWords;

    event RandomWordsRequested(uint256 indexed requestId, address indexed player);
    event RandomWordsFulfilled(uint256 indexed requestId, uint256[] randomWords);
    event ItemDropped(address indexed player, uint256 indexed itemId, uint256 amount);

    constructor(
        address _vrfCoordinator,
        uint64 _subscriptionId,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        _transferOwnership(msg.sender);
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        numWords = _numWords;
    }

    function initialize(address _equipment) external onlyOwner {
        require(address(equipment) == address(0), "Already initialized");
        equipment = IEquipment(_equipment);
    }

    function requestRandomDrop(address player, uint256 dropRateBonus) external {
        uint256 requestId =
            vrfCoordinator.requestRandomWords(keyHash, subscriptionId, requestConfirmations, callbackGasLimit, numWords);

        dropRequests[requestId] = DropRequest({ player: player, dropRateBonus: dropRateBonus, fulfilled: false });

        emit RandomWordsRequested(requestId, player);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        DropRequest storage request = dropRequests[requestId];
        require(!request.fulfilled, "Request already fulfilled");

        request.fulfilled = true;
        requestToRandomWords[requestId] = randomWords;

        // Process drops using the random words
        for (uint256 i = 0; i < randomWords.length; i++) {
            uint256 rand = randomWords[i];

            // Example: Basic drop rate calculation
            uint256 dropRate = 50 + request.dropRateBonus; // 50% base rate
            if (rand % 100 < dropRate) {
                // Determine item type and amount based on random number
                uint256 itemId = (rand % 5) + 1; // Items 1-5
                uint256 amount = 1;

                // Mint the item
                equipment.mint(request.player, itemId, amount, "");
                emit ItemDropped(request.player, itemId, amount);
            }
        }

        emit RandomWordsFulfilled(requestId, randomWords);
    }

    function setCallbackGasLimit(uint32 _callbackGasLimit) external onlyOwner {
        callbackGasLimit = _callbackGasLimit;
    }

    function setRequestConfirmations(uint16 _requestConfirmations) external onlyOwner {
        requestConfirmations = _requestConfirmations;
    }

    function setNumWords(uint32 _numWords) external onlyOwner {
        numWords = _numWords;
    }
}
