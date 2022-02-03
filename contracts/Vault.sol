pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./NFToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Vault is ERC721Holder{

    struct RecievedNFT{
        uint256 internalId;
        address nftAddr;
        uint256 tokenId;
        address sender;
        address tokenAddr;
    }

    uint256 internalIdCounter = 0;

    event Recieved(address from, uint256 tokenId, uint256 internalId, address nftAddr);

    //mapping(interalIds => RecievedNFT)
    mapping(uint256 => RecievedNFT) recievedNfts;

    //mapping(wallet => mapping(internalIds => amountDeposited));
    mapping(address => mapping(uint256 => uint256)) deposits;

    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public override returns(bytes4){
        RecievedNFT memory recievedNft;
        recievedNft.internalId = internalIdCounter;
        recievedNft.nftAddr = msg.sender; 
        recievedNft.sender = from;
        recievedNft.tokenId = tokenId;

        recievedNfts[internalIdCounter] = recievedNft;

        emit Recieved(recievedNft.sender, recievedNft.tokenId, recievedNft.internalId, recievedNft.nftAddr);

        internalIdCounter += 1;
        return this.onERC721Received.selector;
    }

    function mintTokensForNFT(uint256 supply, string memory name, string memory ticker, uint256 internalId) public returns(NFToken){
        require(recievedNfts[internalId].sender == msg.sender, "You did not deposit this NFT.");
        require(recievedNfts[internalId].tokenAddr == address(0), "This NFT has already been fractionalized.");
        NFToken deployedERC = ERCDeployer(msg.sender, internalId, supply, name, ticker);
        recievedNfts[internalId].tokenAddr = address(deployedERC);
        return deployedERC;
    }

    function ERCDeployer(address reciever, uint256 internalId, uint256 supply, string memory name, string memory ticker) private returns(NFToken){
        address[] memory defaultOperators;
        NFToken nfToken = new NFToken(reciever, supply, name, ticker);
        return nfToken;
    }
    
    function buyoutERC721(uint256 internalId, address account) public {
        require(getDepositAmount(internalId, account) == getNFTokenSupply(internalId), "You have not deposited ALL of the fractionalized tokens");       
        IERC721 erc721 = IERC721(getERC721ContractAddr(internalId));
        erc721.transferFrom(address(this), account, getERC721TokenId(internalId));
    }

    function getERC721TokenId(uint256 internalId) public view returns(uint256){
        return recievedNfts[internalId].tokenId;
    }

    function getERC721ContractAddr(uint256 internalId) public view returns(address){
        return recievedNfts[internalId].nftAddr;
    }

    /*
    Returns total supply of tokens DIVIDED by (10**18)
    */
    function getNFTokenSupply(uint256 internalId) public view returns(uint256) {
        NFToken nfToken = NFToken(getNFTokenAddr(internalId));
        return nfToken.totalSupply()/(10**18);
    }

    /*
    YOU CAN ONLY WITHDRAW EVEN NUMBER OF TOKENS!!!!
    */
    function withdrawNFToken(uint256 internalId, address account, uint256 amount) public {
        require(amount >= getDepositAmount(internalId, account), "You do not have that many tokens");
        deposits[account][internalId] -= amount;
        NFToken nfToken = NFToken(getNFTokenAddr(internalId));
        nfToken.transfer(account, amount*(10**18));
    }

    function getDepositAmount(uint256 internalId, address account) public view returns(uint256){
        return deposits[account][internalId];
    }

    /*
    YOU CAN ONLY DEPOSIT EVEN NUMBER OF TOKENS!!!!
    */
    function depositNFToken(uint256 internalId, address account, uint256 amount) public {
        require(getNFTokenBalance(internalId, account) >= amount, "You do not have that many tokens.");
        NFToken nfToken = NFToken(getNFTokenAddr(internalId));
        nfToken.transferFrom(account, address(this), amount*(10**18));
        deposits[account][internalId] += amount;
    }

    /*
    CAN ONLY APPROVE EVEN NUMBERS!!!
    */
    function approveNFTokenTransfer(uint256 internalId, address account, uint256 amount) public {
        NFToken nfToken = NFToken(getNFTokenAddr(internalId));
        nfToken.approve(account, address(this), amount);
    }

    function getNFTokenBalance(uint256 internalId, address account) public view returns(uint256){
        NFToken nfToken = NFToken(getNFTokenAddr(internalId));
        return nfToken.balanceOf(address(account))/(10**18);
    }

    /*
    Returns the last used internalId
    */
    function getInternalIdCounter() public view returns(uint256){
        return internalIdCounter - 1;
    }

    function getNumberDepositedERC721s() public view returns(uint256){
        return internalIdCounter;
    }

    function getNFTContractAddr(uint256 internalId) public view returns(address){
        return recievedNfts[internalId].nftAddr;
    }

    function getNFTokenAddr(uint256 internalId) public view returns(address){
        return recievedNfts[internalId].tokenAddr;
    }
}