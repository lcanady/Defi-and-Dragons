// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IGameToken.sol";

contract GameToken is IGameToken, ERC20, Ownable {
    mapping(address => bool) public questContracts;
    mapping(address => bool) public marketplaceContracts;

    constructor() ERC20("Game Token", "GAME") Ownable(msg.sender) { }

    modifier onlyQuestOrOwner() {
        require(questContracts[msg.sender] || msg.sender == owner(), "Not authorized");
        _;
    }

    modifier onlyMarketplaceOrOwner() {
        require(marketplaceContracts[msg.sender] || msg.sender == owner(), "Not authorized");
        _;
    }

    function setQuestContract(address questContract, bool authorized) public onlyOwner {
        questContracts[questContract] = authorized;
    }

    function setMarketplaceContract(address marketplaceContract, bool authorized) public onlyOwner {
        marketplaceContracts[marketplaceContract] = authorized;
    }

    function mint(address to, uint256 amount) public onlyQuestOrOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyMarketplaceOrOwner {
        _burn(from, amount);
    }
}
