pragma solidity ^0.8.0;

import "./test_Vault.sol";

contract BucketVault is Vault{

    struct Bucket{
        address tokenAddr;
        uint256 bucketId;
        uint256[] NFTIds; 
    }

    uint256 internalIdCounter = 0;

    //mapping(bucketIds => Bucket)
    mapping(uint256 => Bucket) buckets;

    function calcPrice(uint256 _internalId, uint256 _amountTokens) public override returns(uint256){
        IVault vault = IVault(vaultAddr);
        Bucket memory bucket = getBucket(bucketId);
        uint256 price = 0;
        for(uint256 i; i<bucket.NFTIds.length; i++){
            //Add price of every FRAC token
            price += vault.calculateAmountOfwEth(amountOfBuck, bucket.NFTIds[i]);
        }
        return price;
    }

    function buy(uint256 _internalId, uint256 _amountToBuy) public override {

    }

    function sell(uint256 _internalId, uint256 _amountToSell) public override{
        
    }

    function createBucket(uint256[] memory NFTIds, string memory name, string memory ticker) public returns(uint256){
        
    }

}