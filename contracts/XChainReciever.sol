pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract XChainVault is ERC721Holder{

    struct RecievedNFT{
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
    mapping(uint256 => RecievedNFT) recievedNfts;

    //Keep track of all Internal Ids ever owned by a user.
    mapping(address => uint256[]) ownedInternalIds;
    mapping(address => uint256) numIdsOwned;

    event XChainRecieved(address from, uint256 tokenId, uint256 internalId, address nftAddr);
    event XChainReleased(address to, uint256 tokenId, uint256 internalId, address nftAddr);

    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

/*
    constructor(address oracle){
        _setupRole(ORACLE_ROLE, oracle);
    }*/

    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public override returns(bytes4){
        RecievedNFT memory recievedNft;
        recievedNft.internalId = internalIdCounter;
        recievedNft.nftAddr = msg.sender; 
        recievedNft.sender = from;
        recievedNft.tokenId = tokenId;
        recievedNft.owned = true;

        recievedNfts[internalIdCounter] = recievedNft;
        
        //Keep track of all Internal Ids ever owned by a user.
        ownedInternalIds[recievedNft.nftAddr].push(recievedNft.internalId);
        numIdsOwned[recievedNft.nftAddr] += 1;

        emit XChainRecieved(recievedNft.sender, recievedNft.tokenId, recievedNft.internalId, recievedNft.nftAddr);

        internalIdCounter += 1;
        return this.onERC721Received.selector;
    }

    /*
    function releaseNFT(address to, uint256 internalId) public onlyRole(ORACLE_ROLE) {
        IERC721 erc721 = IERC721(getERC721ContractAddr(internalId));
        erc721.transferFrom(address(this), account, getERC721TokenId(internalId));
        
        //If nft gets bought out, decrement the senders owned internalIds
        numIdsOwned[recievedNfts[internalId].sender] -= 1;

        emit XChainReleased(to, getERC721TokenId(internalId), internalId, nftAddr);
    }*/

    function getERC721TokenId(uint256 internalId) public view returns(uint256){
        return recievedNfts[internalId].tokenId;
    }

    function getERC721ContractAddr(uint256 internalId) public view returns(address){
        return recievedNfts[internalId].nftAddr;
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