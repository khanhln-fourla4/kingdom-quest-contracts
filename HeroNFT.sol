// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

import "./erc721-core/NFTCore.sol";
import "./model/HeroInfo.sol";

contract HeroNFT is EIP712, NFTCore {
    using SafeMath for uint256;

    // roles
    mapping(address => bool) private _enhancers;

    // data
    mapping(uint256 => HeroInfo) private _heroes;

    bytes32 private immutable _TYPE_HASH;

    event MintHero(address owner, uint256 indexed heroId);

    event EnhanceHero(uint256 indexed heroId, uint256 level, uint256 newLevel);
    event PunishHero(uint256 indexed heroId, uint256 level, uint256 newLevel);

    constructor(string memory name, string memory symbol)
        NFTCore(name, symbol)
        EIP712(name, "1")
    {
        _TYPE_HASH = keccak256(
            "MintHero(address owner,uint256 id,uint256 birth,uint256 generation,uint256 class,uint256 rarity,uint256 level,string avatar)"
        );
    }

    modifier onlyEnhancer() {
        require(_enhancers[_msgSender()], "Hero: only enhancer");
        _;
    }

    function setEnhancer(address enhancer, bool active) external onlyOwner {
        _enhancers[enhancer] = active;
    }

    function getEnhancer(address enhancer) public view returns (bool) {
        return _enhancers[enhancer];
    }

    function mintHero(
        uint256 id,
        uint256 birth,
        uint256 generation,
        uint256 class,
        uint256 rarity,
        uint256 level,
        string memory avatar,
        bytes memory signature
    ) public {
        require(!_heroes[id].initialized, "Hero: minted");

        bytes32 structHash = keccak256(
            abi.encode(
                _TYPE_HASH,
                _msgSender(),
                id,
                birth,
                generation,
                class,
                rarity,
                level,
                keccak256(bytes(avatar))
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, signature);

        require(signer == owner(), "Hero: invalid signature");

        HeroInfo memory hero = HeroInfo(
            id,
            birth,
            generation,
            class,
            rarity,
            level,
            avatar,
            true
        );

        _heroes[id] = hero;

        _safeMint(_msgSender(), id);

        emit MintHero(_msgSender(), id);
    }

    function enhance(uint256 heroId, uint256 level) external onlyEnhancer {
        HeroInfo storage hero = _heroes[heroId];

        require(hero.level + level <= 15, "Hero: out of level");

        hero.level += level;

        emit EnhanceHero(heroId, level, hero.level);
    }

    function punish(uint256 heroId, uint256 level) external onlyEnhancer {
        HeroInfo storage hero = _heroes[heroId];

        require((hero.level - level >= 0), "Hero: out of level");

        hero.level -= level;

        emit PunishHero(heroId, level, hero.level);
    }

    function getHeroInfo(uint256 heroId) public view returns (HeroInfo memory) {
        return _heroes[heroId];
    }

    function getHeroesByOwner(address owner)
        public
        view
        returns (HeroInfo[] memory)
    {
        uint256 total = balanceOf(owner);

        HeroInfo[] memory hs = new HeroInfo[](total);

        for (uint256 i = 0; i < total; i++) {
            uint256 heroId = tokenOfOwnerByIndex(owner, i);

            HeroInfo memory hero = _heroes[heroId];

            hs[i] = hero;
        }

        return hs;
    }

    function getHeroIdsByOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 total = balanceOf(owner);

        uint256[] memory ids = new uint256[](total);

        for (uint256 i = 0; i < total; i++) {
            ids[i] = tokenOfOwnerByIndex(owner, i);
        }

        return ids;
    }

    function isOwner(address owner, uint256 heroId) public view returns (bool) {
        return ownerOf(heroId) == owner;
    }
}
