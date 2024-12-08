// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "./interfaces/IEquipment.sol";

contract ItemDrop is VRFConsumerBaseV2, Ownable {
    VRFCoordinatorV2Interface private immutable coordinator;
    IEquipment private immutable equipment;

    // Chainlink VRF configuration
    bytes32 private immutable keyHash;
    uint64 private immutable subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant CALLBACK_GAS_LIMIT = 200000;
    uint32 private constant NUM_WORDS = 1;

    // Drop request tracking
    struct DropRequest {
        address player;
        uint256 dropTableId;
        bool fulfilled;
    }
    
    mapping(uint256 => DropRequest) public dropRequests;
    
    // Drop table configuration
    struct DropEntry {
        uint256 equipmentId;
        uint16 weight;  // Relative probability weight (1-1000)
    }
    
    struct DropTable {
        string name;
        uint16 totalWeight;
        bool active;
        DropEntry[] entries;
    }
    
    mapping(uint256 => DropTable) public dropTables;
    
    // Events
    event DropRequested(uint256 indexed requestId, address indexed player, uint256 dropTableId);
    event DropFulfilled(uint256 indexed requestId, address indexed player, uint256 equipmentId);
    event DropTableCreated(uint256 indexed dropTableId, string name);
    event DropTableUpdated(uint256 indexed dropTableId, string name);

    constructor(
        address _vrfCoordinator,
        address _equipment,
        bytes32 _keyHash,
        uint64 _subscriptionId
    ) VRFConsumerBaseV2(_vrfCoordinator) Ownable(msg.sender) {
        coordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        equipment = IEquipment(_equipment);
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
    }

    function createDropTable(
        uint256 dropTableId,
        string memory name,
        DropEntry[] memory entries
    ) external onlyOwner {
        require(!dropTables[dropTableId].active, "Drop table already exists");
        require(entries.length > 0, "Must have at least one entry");

        uint16 totalWeight;
        for (uint i = 0; i < entries.length; i++) {
            require(entries[i].weight > 0 && entries[i].weight <= 1000, "Invalid weight");
            totalWeight += entries[i].weight;
        }

        dropTables[dropTableId] = DropTable({
            name: name,
            totalWeight: totalWeight,
            active: true,
            entries: entries
        });

        emit DropTableCreated(dropTableId, name);
    }

    function requestDrop(uint256 dropTableId) external returns (uint256) {
        require(dropTables[dropTableId].active, "Drop table not active");
        
        uint256 requestId = coordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );

        dropRequests[requestId] = DropRequest({
            player: msg.sender,
            dropTableId: dropTableId,
            fulfilled: false
        });

        emit DropRequested(requestId, msg.sender, dropTableId);
        return requestId;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        DropRequest storage request = dropRequests[requestId];
        require(!request.fulfilled, "Request already fulfilled");
        
        DropTable storage dropTable = dropTables[request.dropTableId];
        uint256 roll = (randomWords[0] % dropTable.totalWeight) + 1;
        
        uint256 selectedEquipmentId;
        uint16 currentTotal;
        
        for (uint i = 0; i < dropTable.entries.length; i++) {
            currentTotal += dropTable.entries[i].weight;
            if (roll <= currentTotal) {
                selectedEquipmentId = dropTable.entries[i].equipmentId;
                break;
            }
        }

        request.fulfilled = true;
        equipment.mint(request.player, selectedEquipmentId, 1, "");
        
        emit DropFulfilled(requestId, request.player, selectedEquipmentId);
    }

    function getDropTable(uint256 dropTableId) external view returns (
        string memory name,
        uint16 totalWeight,
        bool active,
        DropEntry[] memory entries
    ) {
        DropTable storage dropTable = dropTables[dropTableId];
        return (
            dropTable.name,
            dropTable.totalWeight,
            dropTable.active,
            dropTable.entries
        );
    }
}
