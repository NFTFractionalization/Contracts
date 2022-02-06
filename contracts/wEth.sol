// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract wEth is ERC20 {
    constructor(uint256 initialSupply) ERC20("wEth", "wEth") {
        _mint(msg.sender, initialSupply);
    }

    function give(uint256 amountToGive) public {
        _mint(msg.sender, amountToGive);

    }

    function giveAccount(address account, uint256 amountToGive) public {
        _mint(msg.sender, amountToGive);

    }
}