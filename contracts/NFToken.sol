// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NFToken is ERC20 {
    constructor(address reciever, uint256 initialSupply, string memory name, string memory ticker) ERC20(name, ticker) {
        _mint(reciever, initialSupply*(10**18));
    }

    /*
    DONT USE THIS IN PRODUCTION, IT MIGHT LET ANYBODY APPROVE ANY TOKEN TO ANYWHERE!!!!
    */
    function approve(address owner, address spender, uint256 amount) public {
        _approve(owner, spender, amount*(10**18));
    }
}