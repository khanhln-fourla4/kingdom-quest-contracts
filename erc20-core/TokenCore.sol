// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract TokenCore is ERC20, ERC20Burnable {
    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {}
}
