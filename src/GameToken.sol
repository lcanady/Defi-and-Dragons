// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IGameToken.sol";
import "./interfaces/Errors.sol";

contract GameToken is IGameToken, ERC20, Ownable {
    mapping(address => bool) public questContracts;
    mapping(address => bool) public marketplaceContracts;

    constructor() ERC20("Game Token", "GAME") {
        _transferOwnership(msg.sender);
    }

    modifier onlyQuestOrOwner() {
        if (!questContracts[msg.sender] && msg.sender != owner()) revert NotAuthorized();
        _;
    }

    modifier onlyMarketplaceOrOwner() {
        if (!marketplaceContracts[msg.sender] && msg.sender != owner()) revert NotAuthorized();
        _;
    }

    function setQuestContract(address questContract, bool authorized) external onlyOwner {
        if (questContract == address(0)) revert ZeroAddress();
        questContracts[questContract] = authorized;
    }

    function setMarketplaceContract(address marketplaceContract, bool authorized) external onlyOwner {
        if (marketplaceContract == address(0)) revert ZeroAddress();
        marketplaceContracts[marketplaceContract] = authorized;
    }

    function mint(address to, uint256 amount) external onlyQuestOrOwner {
        if (to == address(0)) revert ZeroAddress();
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyMarketplaceOrOwner {
        _burn(from, amount);
    }
}
