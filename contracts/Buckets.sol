pragma solidity ^0.8.0;

import "./NFToken.sol";

interface IVault{
    function buyTokens(uint256 internalId, uint256 amount, address buyer) external;
    function sellTokens(uint256 internalId, uint256 amountOfwEthToBuy, address seller) external;
    function getwEthAddr() external returns(address);
    function calculateAmountOfwEth(uint256 _amountOfFrac, uint256 _internalId) external view returns(uint256);
    function calculateAmountOfFrac(uint256 _amountOfwEth, uint256 _internalId) external view returns(uint256);
    function getNFTokenSupply(uint256 internalId) external returns(uint256);
}

contract Buckets{

    address vaultAddr;
    constructor(address _vaultAddr){
        vaultAddr = _vaultAddr;
    }

    struct Bucket{
        address tokenAddr;
        uint256 bucketId;
        uint256[] NFTIds; 
    }

    uint256 bucketIdCounter = 0;

    //mapping(bucketIds => Bucket)
    mapping(uint256 => Bucket) buckets;

    function ERCDeployer(address reciever, uint256 supply, string memory name, string memory ticker) private returns(NFToken){
        address[] memory defaultOperators;
        NFToken nfToken = new NFToken(reciever, supply, name, ticker);
        return nfToken;
    }

    //==========================================================================================
    //  Create Bucket:
    //    
    //  1. Create vault interface
    //  2. Make sure all NFTs in bucket have been fractionalized
    //  3. Create bucket struct
    //  4. Deploy new BUCK token with 0 supply
    //  5. Set bucketid to IdCounter, token address to the BUCK address, and the NFTIds 
    //  6. Add new bucket struct to bucket mapping
    //  7. Increase bucket counter
    //  8. Return bucket id
    //==========================================================================================
    function createBucket(uint256[] memory NFTIds, string memory name, string memory ticker) public returns(uint256){
        IVault vault = IVault(vaultAddr);
        for(uint256 i=0; i<NFTIds.length; i++){
            require(vault.getNFTokenSupply(NFTIds[i]) > 0, "This token has not been minted yet!!!"); 
        }
        
        Bucket memory bucket;

        NFToken BUCK = ERCDeployer(address(this), 0, name, ticker); 

        bucket.bucketId = bucketIdCounter;
        bucket.tokenAddr = address(BUCK);
        bucket.NFTIds = NFTIds; 

        buckets[bucket.bucketId] = bucket;

        bucketIdCounter += 1;

        return(bucket.bucketId);
    }

    //=========================================
    //  Calculate Bucket Price (buy or sell)
    //
    //  BUCK price = sum of NFT FRAC prices
    //=========================================
    function calcBucketPrice(uint256 bucketId, uint256 amountOfBuck) public view returns(uint256){
        IVault vault = IVault(vaultAddr);
        Bucket memory bucket = getBucket(bucketId);
        uint256 price = 0;
        for(uint256 i = 0; i<bucket.NFTIds.length; i++){
            //Add price of every FRAC token
            price += vault.calculateAmountOfwEth(amountOfBuck, bucket.NFTIds[i]);
        }
        return price;
    }


    // //Calc sell "Price"
    // function calcSellPrice(uint256 bucketId, uint256 amountToSell) public returns(uint256){
    //     IVault vault = IVault(vaultAddr);
    //     Bucket memory bucket = getBucket(bucketId);
    //     uint256 price = 0;
    //     for(uint256 i; i<bucket.NFTIds.length; i++){
    //         //Add price of every FRAC token
    //         price += vault.calculateAmountOfFrac(amountToSell, bucket.NFTIds[i]);
    //     }
    //     return price;
    // }

    function buyBucket(uint256 bucketId, uint256 amount, address account) public {
        IVault vault = IVault(vaultAddr);
        Bucket memory bucket = getBucket(bucketId);
        IERC20 wEth = IERC20(vault.getwEthAddr());
        NFToken BUCK = NFToken(bucket.tokenAddr);

        uint256 bucketPrice = calcBucketPrice(bucketId, amount);
        require(wEth.transferFrom(account, address(this), bucketPrice), "Transfer of wEth failed");
        wEth.approve(vaultAddr, bucketPrice);
        for(uint256 i; i<bucket.NFTIds.length; i++){
            //buy every FRAC token and transfer it to this contract
            vault.buyTokens(bucket.NFTIds[i], amount, address(this));
        }
        BUCK.mint(account, amount);
    }

    function sellBucket(uint256 bucketId, uint256 amount) public {
        IVault vault = IVault(vaultAddr);
        Bucket memory bucket = getBucket(bucketId);
        IERC20 wEth = IERC20(vault.getwEthAddr());
        NFToken BUCK = NFToken(bucket.tokenAddr);

        uint256 sellPrice = calcBucketPrice(bucketId, amount);
        BUCK.burn(msg.sender, amount);
        
        for(uint256 i; i<bucket.NFTIds.length; i++){
            //sell every FRAC token and transfer it to this contract
            vault.sellTokens(bucket.NFTIds[i], amount, address(this));
        }
        require(wEth.transfer(address(this), sellPrice), "Transfer of wEth failed");
    }

    //This is what I should have done instead of the 10000000000 getter functions in the Vault contract!
    function getBucket(uint256 bucketId) public view returns(Bucket memory){
        return buckets[bucketId];
    }

    function getBuckTokenAddr(uint256 bucketId) public view returns(address){
        return buckets[bucketId].tokenAddr;
    }

    function getNumberBucketsCreated() public view returns(uint256){
        return bucketIdCounter;
    }
}