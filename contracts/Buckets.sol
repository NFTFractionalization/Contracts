pragma solidity ^0.8.0;

import "./NFToken.sol";

contract Buckets{
    struct Bucket{
        string chain; 
        bool native; //true if nft is NOT XChain
        uint256 internalId;
        uint256 tokenId;
        address tokenAddr;
        uint256 tokenPrice;
        bool owned; // cross chain stuff 
        uint256[] NFTIds; 
    }
    uint256 internalIdCounterBuckets = 0;

    mapping(uint256 => Bucket) buckets;

    function ERCDeployer(address reciever, uint256 internalId, uint256 supply, string memory name, string memory ticker) private returns(NFToken){
        address[] memory defaultOperators;
        NFToken nfToken = new NFToken(reciever, supply, name, ticker);
        return nfToken;
    }

    function createBucket(uint256[] memory NFTIds, uint256 numNFTs, uint256 internalId, uint256 supply, string memory name, string memory ticker) public{
        Bucket memory bucket;

        bucket.internalId = internalId; 

        NFToken BUCK = ERCDeployer(address(this), internalId, supply, name, ticker); 

        bucket.tokenId = hashIds(NFTIds, numNFTs);
        bucket.tokenAddr = address(BUCK);
        bucket.tokenPrice = 1; // set this later (right now 1 wrapped eth per bucket)

        bucket.NFTIds = NFTIds; 

    }

    function hashIds(uint256[] memory NFTIds, uint256 numNFTs) internal returns(uint256){

    }
}