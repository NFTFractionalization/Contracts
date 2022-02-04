pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./NFToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {FixedMath} from "./FixedMath.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Vault is ERC721Holder, AccessControl{

    struct RecievedNFT{
        string chain;
        //true if nft is NOT XChain
        bool native;
        uint256 internalId;
        address nftAddr;
        uint256 tokenId;
        address sender;
        address tokenAddr;
        uint256 tokenPrice;
        //Is this NFT still in our contract
        bool owned;
    }

    bytes32 public constant OWNER = keccak256("OWNER");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    address wEthAddr;

    uint256 internalIdCounter = 0;

    event XChainRegistered(address from, uint256 tokenId, uint256 internalId, address nftAddr, string chain);
    event XChainRelease(address to, uint256 tokenId, uint256 internalId, address nftAddr, string chain);
    event Recieved(address from, uint256 tokenId, uint256 internalId, address nftAddr);
    event Released(address to, uint256 tokenId, uint256 internalId, address nftAddr);
    
    //mapping(interalIds => RecievedNFT)
    mapping(uint256 => RecievedNFT) recievedNfts;

    //mapping(wallet => mapping(internalIds => amountDeposited));
    mapping(address => mapping(uint256 => uint256)) deposits;

    //Keep track of all Internal Ids ever owned by a user.
    mapping(address => uint256[]) ownedInternalIds;
    mapping(address => uint256) numIdsOwned;

    constructor(address _wEthAddr, address oracle){
        wEthAddr = _wEthAddr;

        _setupRole(OWNER, msg.sender);

        _setupRole(ORACLE_ROLE, oracle);

        _setRoleAdmin(ORACLE_ROLE, OWNER);
    }

    function grantOracle(address account) public onlyRole(OWNER){
        _grantRole(ORACLE_ROLE, account);
    }

    /*
    TODO: FIGURE OUT HOW TO HANDLE XCHAIN INTERNALIDS WITHOUT FUCKING EVERYTHING UP!!!
     */

    function registerXChainNFT(address sender, uint256 tokenId, uint256 internalId, address nftAddr, string memory chain) public onlyRole(ORACLE_ROLE) {
        RecievedNFT memory recievedNft;
        recievedNft.internalId = internalIdCounter;
        recievedNft.nftAddr = nftAddr; 
        recievedNft.sender = sender;
        recievedNft.tokenId = tokenId;
        recievedNft.tokenPrice = 1;
        recievedNft.owned = true;
        recievedNft.chain = chain;
        recievedNft.native = false;

        recievedNfts[internalIdCounter] = recievedNft;
        
        //Keep track of all Internal Ids ever owned by a user.
        ownedInternalIds[recievedNft.nftAddr].push(recievedNft.internalId);
        numIdsOwned[recievedNft.nftAddr] += 1;

        emit XChainRegistered(sender, tokenId, internalId, nftAddr, chain);

        internalIdCounter += 1;
    }

    function sigmoid(int256 a, int256 b, int c, int256 x) public returns(int256){
        int256 denom = FixedMath.sqrt(FixedMath.add(c, (FixedMath.add(x, -b))**2));
        int256 numor = x - b;
        int256 fract = FixedMath.divide(numor, denom);
        int256 left = FixedMath.add(1, fract);
        int256 y = FixedMath.multiply(a, left);
        return y;
    }

    function getwEthAddr() public returns(address){
        return wEthAddr;
    }

    function calculateAmountOfwEth(uint256 _amountOfFrac, uint256 internalId) public returns(uint256){
        return recievedNfts[internalId].tokenPrice * _amountOfFrac;
    }

    function calculateAmountOfFrac(uint256 _amountOfwEth, uint256 internalId) public returns(uint256){
        return _amountOfwEth / recievedNfts[internalId].tokenPrice; 
    }

    // For bucket buys
    function buyTokens(uint256 internalId, uint256 amountOfFrac, address buyer) public{
        ERC20 frac = ERC20(getNFTokenAddr(internalId));
        ERC20 wEth = ERC20(getwEthAddr());
        uint256 amountOfwEth = calculateAmountOfwEth(amountOfFrac, internalId);
        require(frac.balanceOf(address(this)) >= amountOfFrac, "There are not enough tokens to buy");
        require(wEth.transferFrom(buyer, address(this), amountOfwEth), "Transfer of wEth failed");
        require(frac.transfer( buyer, amountOfFrac), "Transfer of frac token failed");
    }

    // For bucket sells
    function sellTokens(uint256 internalId, uint256 amountOfwEth, address seller) public{
        ERC20 frac = ERC20(getNFTokenAddr(internalId));
        ERC20 wEth = ERC20(getwEthAddr());
        uint256 amountOfFrac = calculateAmountOfFrac(amountOfwEth, internalId);
        require(frac.balanceOf(seller) >= amountOfFrac, "You do not have enough frac tokens");
        require(frac.transferFrom(seller, address(this), amountOfFrac), "Transfer of frac token failed");
        //wEth.approve(seller, amountOfwEth);
        require(wEth.transfer( seller, amountOfwEth), "Transfer of wEth failed");
    }

    // For individual sells
    function sellTokensIndividual(uint256 internalId, uint256 amountOfwEth) public {
        sellTokens(internalId, amountOfwEth, msg.sender);
    }

    // For individual buys
    function buyTokensIndividual(uint256 internalId, uint256 amountOfFrac) public {
        buyTokens(internalId, amountOfFrac, msg.sender);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public override returns(bytes4){
        RecievedNFT memory recievedNft;
        recievedNft.internalId = internalIdCounter;
        recievedNft.nftAddr = msg.sender; 
        recievedNft.sender = from;
        recievedNft.tokenId = tokenId;
        recievedNft.tokenPrice = 1;
        recievedNft.owned = true;
        recievedNft.native = true;

        recievedNfts[internalIdCounter] = recievedNft;
        
        //Keep track of all Internal Ids ever owned by a user.
        ownedInternalIds[recievedNft.nftAddr].push(recievedNft.internalId);
        numIdsOwned[recievedNft.nftAddr] += 1;

        emit Recieved(recievedNft.sender, recievedNft.tokenId, recievedNft.internalId, recievedNft.nftAddr);

        internalIdCounter += 1;
        return this.onERC721Received.selector;
    }

    function mintTokensForNFT(uint256 supply, string memory name, string memory ticker, uint256 internalId, uint256 amountToKeep) public returns(NFToken){
        require(recievedNfts[internalId].sender == msg.sender, "You did not deposit this NFT.");
        require(recievedNfts[internalId].tokenAddr == address(0), "This NFT has already been fractionalized.");
        NFToken deployedERC = ERCDeployer(address(this), internalId, supply, name, ticker);
        deployedERC.approve(address(this), amountToKeep);
        deployedERC.transfer(recievedNfts[internalId].sender, amountToKeep);
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
        if(getERC721Native(internalId)){
            IERC721 erc721 = IERC721(getERC721ContractAddr(internalId));
            erc721.transferFrom(address(this), account, getERC721TokenId(internalId));
        }
        else{
            emit XChainRelease(account, getERC721TokenId(internalId), internalId, getERC721ContractAddr(internalId), getERC721Chain(internalId));
        }
               
        //If nft gets bought out, decrement the senders owned internalIds
        numIdsOwned[recievedNfts[internalId].sender] -= 1;
    }


    //Returns true if ERC721 is NOT a XChain
    function getERC721Native(uint256 internalId) public view returns(bool){
        return recievedNfts[internalId].native;
    }

    function getERC721Chain(uint256 internalId) public view returns(string memory){
        return recievedNfts[internalId].chain;
    }

    function getERC721TokenId(uint256 internalId) public view returns(uint256){
        return recievedNfts[internalId].tokenId;
    }

    function getERC721ContractAddr(uint256 internalId) public view returns(address){
        return recievedNfts[internalId].nftAddr;
    }

    function getNFTokenSupply(uint256 internalId) public view returns(uint256) {
        NFToken nfToken = NFToken(getNFTokenAddr(internalId));
        return nfToken.totalSupply();
    }

    function withdrawNFToken(uint256 internalId, address account, uint256 amount) public {
        require(amount <= getDepositAmount(internalId, account), "You do not have that many tokens");
        deposits[account][internalId] -= amount;
        NFToken nfToken = NFToken(getNFTokenAddr(internalId));
        nfToken.transfer(account, amount);
    }

    function getDepositAmount(uint256 internalId, address account) public view returns(uint256){
        return deposits[account][internalId];
    }

    function depositNFToken(uint256 internalId, address account, uint256 amount) public {
        require(getNFTokenBalance(internalId, account) >= amount, "You do not have that many tokens.");
        NFToken nfToken = NFToken(getNFTokenAddr(internalId));
        nfToken.transferFrom(account, address(this), amount);
        deposits[account][internalId] += amount;
    }

    function approveNFTokenTransfer(uint256 internalId, address account, uint256 amount) public {
        NFToken nfToken = NFToken(getNFTokenAddr(internalId));
        nfToken.thirdPartyApprove(account, address(this), amount);
    }

    function getNFTokenBalance(uint256 internalId, address account) public view returns(uint256){
        NFToken nfToken = NFToken(getNFTokenAddr(internalId));
        return nfToken.balanceOf(address(account));
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

    function getOwned(uint256 internalId) public view returns(bool){
        return recievedNfts[internalId].owned;
    }

    function getNumIdsOwned(address account) public view returns(uint256){
        return numIdsOwned[account];
    }

    // If anything is broken... its because of this function
    function getOwnedInternalIds(address account) public view returns(uint256[] memory){
        uint256 accountNumIdsOwned = getNumIdsOwned(account);
        uint256[] memory ownedIds = new uint256[](accountNumIdsOwned);
        uint256 countOwned = 0;
        for(uint i; i<ownedInternalIds[account].length; i++){
            if(getOwned(ownedInternalIds[account][i])){
                ownedIds[countOwned] = ownedInternalIds[account][i];
                countOwned+=1;
            }
        }
        return(ownedIds);
    }
}