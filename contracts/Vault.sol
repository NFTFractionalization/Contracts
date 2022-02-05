pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./NFToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vault is ERC721Holder, Ownable{
    //using FixedMath for int256;

    struct RecievedNFT{
        uint256 chainId;
        uint256 xChainInternalId;
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

    address wEthAddr;

    uint256 internalIdCounter = 0;

    event XChainRegistered(address from, uint256 tokenId, uint256 internalId, uint256 xChainInternalId, address nftAddr, uint256 chainId);
    event XChainRelease(address to, uint256 tokenId, uint256 internalId, uint256 xChainInternalId, address nftAddr, uint256 chainId);
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
    }

    /*
    TODO: FIGURE OUT HOW TO HANDLE XCHAIN INTERNALIDS WITHOUT FUCKING EVERYTHING UP!!!
     */

    function registerXChainNFT(address sender, uint256 tokenId, uint256 xChainInternalId, address nftAddr, uint256 chainId) public onlyOwner{
        RecievedNFT memory recievedNft;
        recievedNft.internalId = internalIdCounter;
        recievedNft.nftAddr = nftAddr; 
        recievedNft.sender = sender;
        recievedNft.tokenId = tokenId;
        recievedNft.tokenPrice = 1;
        recievedNft.owned = true;
        recievedNft.chainId = chainId;
        recievedNft.xChainInternalId = xChainInternalId;
        recievedNft.native = false;

        recievedNfts[internalIdCounter] = recievedNft;
        
        //Keep track of all Internal Ids ever owned by a user.
        ownedInternalIds[recievedNft.sender].push(recievedNft.internalId);
        numIdsOwned[recievedNft.sender] += 1;

        emit XChainRegistered(recievedNft.sender, recievedNft.tokenId, recievedNft.internalId, recievedNft.xChainInternalId, recievedNft.nftAddr, recievedNft.chainId);

        internalIdCounter += 1;
    }

    // function sigmoid(int256 a, int256 b, int c, int256 x) public returns(int256){
    //     // int256 numerator = int256(x) - midpoint;
    //     // int256 innerSqrt = (steepness + (numerator)**2);
    //     // int256 fixedInner = innerSqrt.toFixed();
    //     // int256 fixedDenominator = fixedInner.sqrt();
    //     // int256 fixedNumerator = numerator.toFixed();
    //     // int256 midVal = fixedNumerator.divide(fixedDenominator) + 1000000000000000000000000;
    //     // int256 fixedFinal = maxPrice.toFixed() * midVal;
    //     // return int256(fixedFinal / 1000000000000000000000000000000);
    //     int256 denom = FixedMath.sqrt(FixedMath.add(c, (FixedMath.add(x, -b))**2));
    //     int256 numor = x - b;
    //     int256 fract = FixedMath.divide(numor, denom);
    //     int256 left = FixedMath.add(1, fract);
    //     int256 y = FixedMath.multiply(a, left);
    //     return y;
    // }

    function getwEthAddr() public view returns(address){
        return wEthAddr;
    }

    function calculateAmountOfwEth(uint256 _amountOfFrac, uint256 internalId) public view returns(uint256){
        return recievedNfts[internalId].tokenPrice * _amountOfFrac;
    }

    function calculateAmountOfFrac(uint256 _amountOfwEth, uint256 internalId) public view returns(uint256){
        return _amountOfwEth / recievedNfts[internalId].tokenPrice; 
    }

    //=======================================================
    //  Buy tokens
    //
    //  1. Create FRAC and wEth objects
    //  2. Calculate cost in wEth for amount of FRAC to buy
    //  3. Make sure we have enough FRAC to give
    //  4. Transfer wEth to us from buyer
    //  5. Transfer FRAC to buyer from us
    //=======================================================
    function buyTokens(uint256 _internalId, uint256 _FracToBuy, address _buyer) public{
        IERC20 frac = IERC20(getNFTokenAddr(_internalId));
        IERC20 wEth = IERC20(getwEthAddr());
        uint256 costInwEth = calculateAmountOfwEth(_FracToBuy, _internalId);
        require(frac.balanceOf(address(this)) >= _FracToBuy, "There are not enough FRAC tokens to buy");
        require(wEth.transferFrom(_buyer, address(this), costInwEth), "Transfer of wEth failed");
        require(frac.transfer(_buyer, _FracToBuy), "Transfer of FRAC token failed");
    }

    //================================================
    //  Sell tokens
    //
    //  Steps are the same as buyTokens, except the
    //  two transfers are in the opposite direction
    //================================================
    function sellTokens(uint256 _internalId, uint256 _FracToSell, address _seller) public{
        IERC20 frac = IERC20(getNFTokenAddr(_internalId));
        IERC20 wEth = IERC20(getwEthAddr());
        uint256 priceInwEth = calculateAmountOfwEth(_FracToSell, _internalId);
        require(frac.balanceOf(_seller) >= _FracToSell, "You do not have enough frac tokens");
        require(frac.transferFrom(_seller, address(this), _FracToSell), "Transfer of frac token failed");
        require(wEth.transfer(_seller, priceInwEth), "Transfer of wEth failed");
    }

    //==========================================================
    //  Buying individual tokens
    //
    //  Calls buyTokens with msg.sender as the buyer address
    //==========================================================
    function buyTokensIndividual(uint256 internalId, uint256 FracToBuy) public {
        buyTokens(internalId, FracToBuy, msg.sender);
    }

    //==========================================================
    //  Selling individual tokens
    //
    //  Calls sellTokens with msg.sender as the seller address
    //==========================================================
    function sellTokensIndividual(uint256 internalId, uint256 amountOfwEth) public {
        sellTokens(internalId, amountOfwEth, msg.sender);
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
        ownedInternalIds[recievedNft.sender].push(recievedNft.internalId);
        numIdsOwned[recievedNft.sender] += 1;

        emit Recieved(recievedNft.sender, recievedNft.tokenId, recievedNft.internalId, recievedNft.nftAddr);

        internalIdCounter += 1;
        return this.onERC721Received.selector;
    }

    function mintTokensForNFT(uint256 supply, string memory name, string memory ticker, uint256 internalId, uint256 amountToKeep) public returns(NFToken){
        require(recievedNfts[internalId].sender == msg.sender, "You did not deposit this NFT.");
        require(recievedNfts[internalId].tokenAddr == address(0), "This NFT has already been fractionalized.");
        NFToken deployedERC = ERCDeployer(address(this), supply, name, ticker);
        deployedERC.approve(address(this), amountToKeep);
        deployedERC.transfer(recievedNfts[internalId].sender, amountToKeep);
        recievedNfts[internalId].tokenAddr = address(deployedERC);
        return deployedERC;
    }

    function ERCDeployer(address reciever, uint256 supply, string memory name, string memory ticker) private returns(NFToken){
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
            emit XChainRelease(account, getERC721TokenId(internalId), internalId, getERC721XChainInternalId(internalId), getERC721ContractAddr(internalId), getERC721ChainId(internalId));
        }
               
        //If nft gets bought out, decrement the senders owned internalIds
        numIdsOwned[recievedNfts[internalId].sender] -= 1;
    }


    //Returns true if ERC721 is NOT a XChain
    function getERC721Native(uint256 internalId) public view returns(bool){
        return recievedNfts[internalId].native;
    }

    function getERC721ChainId(uint256 internalId) public view returns(uint256){
        return recievedNfts[internalId].chainId;
    }

    function getERC721XChainInternalId(uint256 internalId) public view returns(uint256){
        return recievedNfts[internalId].xChainInternalId;
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

/*
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
    }*/
}