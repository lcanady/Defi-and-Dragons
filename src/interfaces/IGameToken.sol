// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IGameToken {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function setQuestContract(address questContract, bool authorized) external;
    function setMarketplaceContract(address marketplaceContract, bool authorized) external;
}
