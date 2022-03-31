// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./../model/HeroInfo.sol";

interface IHeroNFT {
    function getHeroInfo(uint256 heroId)
        external
        view
        returns (HeroInfo memory);

    function isOwner(address owner, uint256 heroId)
        external
        view
        returns (bool);

    function burn(uint256 tokenId) external;
    function enhance(uint256 heroId, uint256 level) external;
    function punish(uint256 heroId, uint256 level) external;
}
