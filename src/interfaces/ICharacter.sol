// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Types.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ICharacter is IERC721 {
    function getCharacter(uint256 tokenId)
        external
        view
        returns (Types.Stats memory stats, Types.EquipmentSlots memory equipment, Types.CharacterState memory state);

    function mintCharacter(address to, Types.Alignment alignment)
        external
        returns (uint256);
}
