// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

struct HeroInfo {
    uint256 id;
    uint256 birth; // created timestamp
    // from where
    uint256 generation;
    // info
    uint256 class; // random
    uint256 rarity; // random
    uint256 level; // init 0
    // avatar
    // uint256 set; // head - clothes - shoes - gloves
    // uint256 body; // random
    // uint256 eyes; // random
    // uint256 mouth; // random
    // uint256 leftWeapon; // random
    // uint256 rightWeapon; // random
    string avatar;
    bool initialized;
}
