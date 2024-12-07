// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GameToken is ERC20, Ownable {
    // Quest contract address that can mint rewards
    address public questContract;
    
    // Events
    event QuestContractUpdated(address indexed oldQuestContract, address indexed newQuestContract);

    constructor() ERC20("DnD Gold", "GOLD") Ownable(msg.sender) {}

    /**
     * @dev Set the quest contract address
     * @param _questContract Address of the quest contract
     */
    function setQuestContract(address _questContract) external onlyOwner {
        emit QuestContractUpdated(questContract, _questContract);
        questContract = _questContract;
    }

    /**
     * @dev Mint tokens as quest rewards
     * @param to Address to receive the tokens
     * @param amount Amount of tokens to mint
     */
    function mintQuestReward(address to, uint256 amount) external {
        require(msg.sender == questContract, "Only quest contract can mint rewards");
        _mint(to, amount);
    }

    /**
     * @dev Burn tokens (for marketplace fees, crafting costs, etc.)
     * @param amount Amount of tokens to burn
     */
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Burn tokens from an approved address
     * @param account Address to burn tokens from
     * @param amount Amount of tokens to burn
     */
    function burnFrom(address account, uint256 amount) public {
        _spendAllowance(account, msg.sender, amount);
        _burn(account, amount);
    }
} 