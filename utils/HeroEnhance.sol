// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./../model/HeroInfo.sol";
import "./../interface/IHeroNFT.sol";

contract HeroEnhance {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    uint256 private constant MAX_LEVEL = 15;
    uint256 private constant BASE_SUCCESS_RATE = 80;
    uint256 private constant SUCCESS_RATE_STEP = 5;
    uint256 private constant BASE_ENHANCE_POINT = 100_00;
    uint256 private constant ENHANCE_POINT_STEP = 125; // 1.25

    IHeroNFT private heroNFT;
    Counters.Counter private _nonce;

    event EnhanceResult(
        address owner,
        uint256 heroId,
        bool success,
        uint256 level
    );

    constructor(address heroAddress) {
        heroNFT = IHeroNFT(heroAddress);
    }

    function enhance(uint256 heroId, uint256[] memory heroes) public {
        require(
            heroNFT.isOwner(msg.sender, heroId),
            "Enhance: you are not owner"
        );

        require(heroes.length <= 5, "Enhance: out-of-range");

        HeroInfo memory hero = heroNFT.getHeroInfo(heroId);

        require(hero.level < MAX_LEVEL, "Enhance: max level");

        uint256 point = 0;

        for (uint256 i = 0; i < heroes.length; i++) {
            if (!heroNFT.isOwner(msg.sender, heroes[i])) {
                revert("Enhance: you are not owner");
            }

            if (heroes[i] == heroId) {
                revert("Enhance: invalid enhance hero");
            }

            HeroInfo memory hr = heroNFT.getHeroInfo(heroes[i]);

            point += getEnhancePoint(hr.rarity, hr.level);

            heroNFT.burn(heroes[i]);
        }

        (bool success, uint256 level) = _enhance(
            hero.rarity,
            hero.level,
            point
        );

        if (success) {
            heroNFT.enhance(heroId, level);
        } else {
            if (level > 0) {
                heroNFT.punish(heroId, level);
            }
        }

        emit EnhanceResult(msg.sender, heroId, success, level);
    }

    function _enhance(
        uint256 rarity,
        uint256 level,
        uint256 point
    ) internal returns (bool, uint256) {
        bool success = _checkEnhance(rarity, level, point);

        if (success) {
            return (success, _exEnhance(rarity, level, point));
        }

        return (success, _punishEnhance(rarity, level, point));
    }

    function _checkEnhance(
        uint256 rarity,
        uint256 level,
        uint256 point
    ) internal returns (bool) {
        uint256 maxSuccessRate = getMaxSuccessRate(level);
        uint256 maxEnhancePoint = getEnhancePoint(rarity, level);
        uint256 successRate = _getSuccessRate(
            maxSuccessRate,
            point,
            maxEnhancePoint
        );

        return _random(100 * 10**6, rarity, level, point) <= successRate;
    }

    function _exEnhance(
        uint256 rarity,
        uint256 level,
        uint256 point
    ) internal returns (uint256) {
        uint256 exSuccessRate = (getExSuccessRate(level) * 10**6) / 100;
        bool ex = _random(10**6, rarity, level, point) <= exSuccessRate;
        return ex ? 2 : 1;
    }

    function _punishEnhance(
        uint256 rarity,
        uint256 level,
        uint256 point
    ) internal returns (uint256) {
        uint256 punishRate = (getPunishRate(level) * 10**6) / 100;
        uint256 punish = 0;

        if (punishRate == 0) {
            return punish;
        }

        uint256 rdPunish = _random(10**6, rarity, level, point);

        if (rdPunish <= punishRate) {
            punish += 1;
        }

        uint256 exPunishRate = (getExPunishRate(level) * 10**6) / 100;

        if (exPunishRate > 0) {
            uint256 rdExPunish = _random(10**6, rarity, level, point);

            if (rdExPunish <= exPunishRate) {
                punish += 1;
            }
        }

        return punish;
    }

    function getSuccessRate(uint256 heroId, uint256[] memory heroes)
        public
        view
        returns (uint256)
    {
        HeroInfo memory hero = heroNFT.getHeroInfo(heroId);

        require(hero.level < MAX_LEVEL, "Enhance: max level");

        uint256 point = 0;

        for (uint256 i = 0; i < heroes.length; i++) {
            if (!heroNFT.isOwner(msg.sender, heroes[i])) {
                revert("Enhance: you are not owner");
            }

            if (heroes[i] == heroId) {
                revert("Enhance: invalid enhance hero");
            }

            HeroInfo memory hr = heroNFT.getHeroInfo(heroes[i]);

            point += getEnhancePoint(hr.rarity, hr.level);
        }

        uint256 maxSuccessRate = getMaxSuccessRate(hero.level);
        uint256 maxEnhancePoint = getEnhancePoint(hero.rarity, hero.level);

        return _getSuccessRate(maxSuccessRate, point, maxEnhancePoint);
    }

    function _getSuccessRate(
        uint256 maxSuccessRate,
        uint256 point,
        uint256 maxPoint
    ) private pure returns (uint256) {
        if (point > maxPoint) {
            return maxSuccessRate * 10**6;
        }

        point *= 10**6;

        uint256 percent = point / maxPoint;

        return maxSuccessRate * percent;
    }

    function getMaxSuccessRate(uint256 level) public pure returns (uint256) {
        if (level >= 15) {
            return 0;
        }

        return BASE_SUCCESS_RATE - (level * SUCCESS_RATE_STEP);
    }

    function getExSuccessRate(uint256 level) public pure returns (uint256) {
        if (level < 10) {
            return 5;
        }

        return 5 - (level - 9);
    }

    function getPunishRate(uint256 level) public pure returns (uint256) {
        if (level < 10) {
            return 0;
        }

        if (level > 12) {
            return 100;
        }

        return 25 * (level - 9);
    }

    function getExPunishRate(uint256 level) public pure returns (uint256) {
        if (level < 10) {
            return 0;
        }

        return 20 * (level - 10);
    }

    function getEnhancePoint(uint256 rarity, uint256 level)
        public
        pure
        returns (uint256)
    {
        if (rarity == 0) {
            return
                (BASE_ENHANCE_POINT * ENHANCE_POINT_STEP**level) /
                (100**(level + 2) / 100);
        }

        uint256 startLevel = rarity * 5;
        uint256 base = BASE_ENHANCE_POINT * ENHANCE_POINT_STEP**startLevel;

        return
            (base * ENHANCE_POINT_STEP**level) /
            (100**(startLevel + level + 2) / 100);
    }

    /// @dev Random a number from [0 to bound - 1]
    /// @param bound the upper bound (exclusive). Must be positive
    /// @return A number
    function _random(
        uint256 bound,
        uint256 rarity,
        uint256 level,
        uint256 point
    ) internal returns (uint256) {
        require(bound > 0, "Invalidate range");

        uint256 nonce = _nonce.current();

        uint256 number = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    msg.sender,
                    rarity,
                    level,
                    point,
                    nonce
                )
            )
        ).mod(bound);

        _nonce.increment();

        return number;
    }
}
