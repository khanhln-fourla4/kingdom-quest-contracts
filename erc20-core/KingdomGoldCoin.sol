// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./TokenCore.sol";

contract KingdomGoldCoin is TokenCore {
    uint256 private TOTAL_SUPPLY = 10 * 10**9;

    constructor() TokenCore("Kingdom Gold Coin", "KGC") {
        _mint(address(msg.sender), TOTAL_SUPPLY * 10**decimals());
    }
}
