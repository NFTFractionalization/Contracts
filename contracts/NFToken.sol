// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFToken is ERC20, Ownable {
    constructor(address reciever, uint256 initialSupply, string memory name, string memory ticker) ERC20(name, ticker) {
        _mint(reciever, initialSupply);
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }

    /*
    DONT USE THIS IN PRODUCTION, IT MIGHT LET ANYBODY APPROVE ANY TOKEN TO ANYWHERE!!!!
    honestly tho, im not sure.
    */
    function thirdPartyApprove(address owner, address spender, uint256 amount) public {
        _approve(owner, spender, amount);
    }
}