pragma solidity ^0.8.0;

import "./test_Vault.sol";

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./NFToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTVault is Vault, ERC721Holder, Ownable{

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

    uint256 internalIdCounter = 0;

    //mapping(interalIds => RecievedNFT)
    mapping(uint256 => RecievedNFT) recievedNFTs;

    //mapping(wallet => mapping(internalIds => amountDeposited));
    mapping(address => mapping(uint256 => uint256)) deposits;

    //Keep track of all Internal Ids ever owned by a user.
    mapping(address => uint256[]) ownedInternalIds;
    mapping(address => uint256) numIdsOwned;

    event XChainRegistered(address from, uint256 tokenId, uint256 internalId, uint256 xChainInternalId, address nftAddr, uint256 chainId);
    event XChainRelease(address to, uint256 tokenId, uint256 internalId, uint256 xChainInternalId, address nftAddr, uint256 chainId);
    event Recieved(address from, uint256 tokenId, uint256 internalId, address nftAddr);
    event Released(address to, uint256 tokenId, uint256 internalId, address nftAddr);

    function calcPrice(uint256 _internalId, uint256 _amountTokens) public override view returns(uint256){
        return recievedNFTs[_internalId].tokenPrice * _amountTokens;
    }

    function buy(uint256 _internalId, uint256 _amountToBuy) public override {
        IERC20 frac = IERC20(getNFTokenAddr(_internalId));
        IERC20 wEth = IERC20(getwEthAddr());
        uint256 costInwEth = calcPrice(_internalId, _amountToBuy);
        require(frac.balanceOf(address(this)) >= _amountToBuy, "There are not enough FRAC tokens to buy");
        require(wEth.transferFrom(msg.sender, address(this), costInwEth), "Transfer of wEth failed");
        require(frac.transfer(msg.sender, _amountToBuy), "Transfer of FRAC token failed");
    }

    function sell(uint256 _internalId, uint256 _amountToSell) public override{
        IERC20 frac = IERC20(getNFTokenAddr(_internalId));
        IERC20 wEth = IERC20(getwEthAddr());
        uint256 priceInwEth = calcPrice(_internalId, _amountToSell);
        require(frac.balanceOf(msg.sender) >= _amountToSell, "You do not have enough frac tokens");
        require(frac.transferFrom(msg.sender, address(this), _amountToSell), "Transfer of frac token failed");
        require(wEth.transfer(msg.sender, priceInwEth), "Transfer of wEth failed");
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

        recievedNFTs[internalIdCounter] = recievedNft;
        
        //Keep track of all Internal Ids ever owned by a user.
        ownedInternalIds[recievedNft.sender].push(recievedNft.internalId);
        numIdsOwned[recievedNft.sender] += 1;

        emit Recieved(recievedNft.sender, recievedNft.tokenId, recievedNft.internalId, recievedNft.nftAddr);

        internalIdCounter += 1;
        return this.onERC721Received.selector;
    }

    function mintTokensForNFT(uint256 supply, string memory name, string memory ticker, uint256 internalId, uint256 amountToKeep) public returns(NFToken){
        require(recievedNFTs[internalId].sender == msg.sender, "You did not deposit this NFT.");
        require(recievedNFTs[internalId].tokenAddr == address(0), "This NFT has already been fractionalized.");
        NFToken deployedERC = ERCDeployer(address(this), supply, name, ticker);
        deployedERC.approve(address(this), amountToKeep);
        deployedERC.transfer(recievedNFTs[internalId].sender, amountToKeep);
        recievedNFTs[internalId].tokenAddr = address(deployedERC);
        return deployedERC;
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
        numIdsOwned[recievedNFTs[internalId].sender] -= 1;
    }


    //Returns true if ERC721 is NOT a XChain
    function getERC721Native(uint256 internalId) public view returns(bool){
        return recievedNFTs[internalId].native;
    }

    function getERC721ChainId(uint256 internalId) public view returns(uint256){
        return recievedNFTs[internalId].chainId;
    }

    function getERC721XChainInternalId(uint256 internalId) public view returns(uint256){
        return recievedNFTs[internalId].xChainInternalId;
    }

    function getERC721TokenId(uint256 internalId) public view returns(uint256){
        return recievedNFTs[internalId].tokenId;
    }

    function getERC721ContractAddr(uint256 internalId) public view returns(address){
        return recievedNFTs[internalId].nftAddr;
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
        return recievedNFTs[internalId].nftAddr;
    }

    function getNFTokenAddr(uint256 internalId) public view returns(address){
        return recievedNFTs[internalId].tokenAddr;
    }

    function getOwned(uint256 internalId) public view returns(bool){
        return recievedNFTs[internalId].owned;
    }

    function getNumIdsOwned(address account) public view returns(uint256){
        return numIdsOwned[account];
    }

}