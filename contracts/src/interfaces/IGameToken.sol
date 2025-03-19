// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGameToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function setQuestContract(address questContract, bool authorized) external;
    function setMarketplaceContract(address marketplaceContract, bool authorized) external;
}
