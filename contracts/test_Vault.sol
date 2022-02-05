pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./NFToken.sol";

abstract contract Vault{

    address wEthAddr; // Temp

    // Temp
    function getwEthAddr() public view returns(address){
        return wEthAddr;
    }

    function calcPrice(uint256 _internalId, uint256 _amountTokens) public virtual returns(uint256);

    function buy(uint256 _internalId, uint256 _amountToBuy) public virtual;

    function sell(uint256 _internalId, uint256 _amountToSell) public virtual;

    function ERCDeployer(address reciever, uint256 supply, string memory name, string memory ticker) internal returns(NFToken){
        address[] memory defaultOperators;
        NFToken nfToken = new NFToken(reciever, supply, name, ticker);
        return nfToken;
    }


}