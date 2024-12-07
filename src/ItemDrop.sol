// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "./Equipment.sol";

contract ItemDrop is VRFConsumerBaseV2, Ownable {
    VRFCoordinatorV2Interface public immutable vrfCoordinator;
    Equipment public equipment;
    
    // Chainlink VRF configuration
    bytes32 public immutable keyHash;
    uint64 public immutable subscriptionId;
    uint16 public constant REQUEST_CONFIRMATIONS = 3;
    uint32 public constant CALLBACK_GAS_LIMIT = 200000;

    // Drop table structure
    struct DropEntry {
        uint256 equipmentId;
        uint256 weight;
        uint256 minAmount;
        uint256 maxAmount;
    }

    // Mapping from drop table ID to array of possible drops
    mapping(uint256 => DropEntry[]) public dropTables;
    
    // Mapping to track pending requests
    mapping(uint256 => address) public pendingRequests;
    mapping(uint256 => uint256) public requestToDropTable;

    // Events
    event DropTableCreated(uint256 indexed dropTableId);
    event DropEntryAdded(uint256 indexed dropTableId, uint256 indexed equipmentId);
    event RandomItemRequested(uint256 indexed requestId, address indexed player);
    event RandomItemAwarded(address indexed player, uint256 indexed equipmentId, uint256 amount);

    constructor(
        address _vrfCoordinator,
        address _equipment,
        bytes32 _keyHash,
        uint64 _subscriptionId
    ) VRFConsumerBaseV2(_vrfCoordinator) Ownable(msg.sender) {
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        equipment = Equipment(_equipment);
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
    }

    /**
     * @dev Create a new drop table
     * @param dropTableId ID for the new drop table
     * @param entries Array of initial drop entries
     */
    function createDropTable(uint256 dropTableId, DropEntry[] memory entries) public onlyOwner {
        require(dropTables[dropTableId].length == 0, "Drop table already exists");
        
        uint256 totalWeight = 0;
        for (uint256 i = 0; i < entries.length; i++) {
            require(entries[i].weight > 0, "Weight must be positive");
            require(entries[i].maxAmount >= entries[i].minAmount, "Invalid amount range");
            totalWeight += entries[i].weight;
            dropTables[dropTableId].push(entries[i]);
        }

        require(totalWeight > 0, "Total weight must be positive");
        emit DropTableCreated(dropTableId);
    }

    /**
     * @dev Add a new entry to an existing drop table
     * @param dropTableId Target drop table ID
     * @param entry New drop entry
     */
    function addDropEntry(uint256 dropTableId, DropEntry memory entry) public onlyOwner {
        require(dropTables[dropTableId].length > 0, "Drop table does not exist");
        require(entry.weight > 0, "Weight must be positive");
        require(entry.maxAmount >= entry.minAmount, "Invalid amount range");
        
        dropTables[dropTableId].push(entry);
        emit DropEntryAdded(dropTableId, entry.equipmentId);
    }

    /**
     * @dev Request a random item drop from a specific table
     * @param dropTableId Drop table to use
     */
    function requestRandomItem(uint256 dropTableId) public returns (uint256 requestId) {
        require(dropTables[dropTableId].length > 0, "Drop table does not exist");
        
        // Request randomness from Chainlink VRF
        requestId = vrfCoordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            1 // number of random words
        );

        pendingRequests[requestId] = msg.sender;
        requestToDropTable[requestId] = dropTableId;
        
        emit RandomItemRequested(requestId, msg.sender);
    }

    /**
     * @dev Callback function used by VRF Coordinator to return the random number
     * @param requestId The ID of the request
     * @param randomWords The array of random results from VRF Coordinator
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        address player = pendingRequests[requestId];
        require(player != address(0), "Request not found");

        uint256 dropTableId = requestToDropTable[requestId];
        DropEntry[] storage entries = dropTables[dropTableId];
        
        // Calculate total weight
        uint256 totalWeight = 0;
        for (uint256 i = 0; i < entries.length; i++) {
            totalWeight += entries[i].weight;
        }

        // Select random item based on weights
        uint256 randomNumber = randomWords[0] % totalWeight;
        uint256 currentWeight = 0;
        
        for (uint256 i = 0; i < entries.length; i++) {
            currentWeight += entries[i].weight;
            if (randomNumber < currentWeight) {
                // Calculate random amount within range
                uint256 amount = entries[i].minAmount;
                if (entries[i].maxAmount > entries[i].minAmount) {
                    amount += (randomWords[0] % (entries[i].maxAmount - entries[i].minAmount + 1));
                }

                // Mint the selected item
                equipment.mint(player, entries[i].equipmentId, amount, "");
                
                emit RandomItemAwarded(player, entries[i].equipmentId, amount);
                break;
            }
        }

        // Clean up
        delete pendingRequests[requestId];
        delete requestToDropTable[requestId];
    }

    /**
     * @dev Get all entries in a drop table
     * @param dropTableId Drop table ID
     */
    function getDropTable(uint256 dropTableId) public view returns (DropEntry[] memory) {
        return dropTables[dropTableId];
    }
} 