const { expect } = require("chai");
const { ethers } = require("hardhat");
const chai = require('chai');
const chaiAlmost = require("chai-almost");

chai.use(chaiAlmost(0.1));

describe("Greeter", function () {
  it("Should return the new greeting once it's changed", async function () {
    const Greeter = await ethers.getContractFactory("Greeter");
    const greeter = await Greeter.deploy("Hello, world!");
    await greeter.deployed();

    expect(await greeter.greet()).to.equal("Hello, world!");

    const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

    // wait until the transaction is mined
    await setGreetingTx.wait();

    expect(await greeter.greet()).to.equal("Hola, mundo!");
  })});

  //https://hardhat.org/tutorial/testing-contracts.html tutorial for testing!

  describe("Vault Tests", function() {
    var minter;
    var vault;
    var wEth;
    var NFToken;
    var buckets;

    beforeEach(async function(){
      const [owner] = await ethers.getSigners();
      NFToken = await ethers.getContractFactory("NFToken");

      const WEth = await ethers.getContractFactory("wEth");
      wEth = await WEth.deploy(1000000);
      await wEth.deployed();
      
      const Minter = await ethers.getContractFactory("Minter");
      minter = await Minter.deploy();
      await minter.deployed();

      // const FixedMath = await ethers.getContractFactory("FixedMath");
      // fixedMath = await FixedMath.deploy();

      const Vault = await ethers.getContractFactory("Vault"/*,{
        libraries: {
          FixedMath: "0x6985897120ca08f1CEAC3C8F909F6bfC9D6F4aa7",
        },
      }*/);
      vault = await Vault.deploy(wEth.address, owner.address);
      await vault.deployed();

      const Buckets = await ethers.getContractFactory("Buckets");
      buckets = await Buckets.deploy(vault.address);
      await buckets.deployed();
      
    });

    it("Should mint new NFT", async function () {
      const [owner] = await ethers.getSigners();
      
      const mintTx = await minter.mint(owner.address);

      const ownerNFTBalance = await minter.balanceOf(owner.address);

      expect(ownerNFTBalance).to.equal(1);
    })

  it("Should deposit NFT into vault and mint tokens into contract", async function (){    
    const [owner] = await ethers.getSigners();

    const mintSupply = 1000000;
    const tokenName = "Frac";
    const tokenTicker = "FRAC";
    const amountToKeep = 500000;
    const tokenInternalId = 0;

    const tokenId = await minter.mint(owner.address);
    
    const ownerNFTBalance = await minter.balanceOf(owner.address);
    expect(ownerNFTBalance).to.equal(1);

    await minter.approve(vault.address, 1)
    await minter.safeTransfer(owner.address, vault.address, 1)

    expect(await vault.getNumberDepositedERC721s()).to.equal(1);
    
    await vault.mintTokensForNFT(ethers.utils.parseUnits(String(mintSupply), 18), tokenName, tokenTicker, tokenInternalId, ethers.utils.parseUnits(String(amountToKeep), 18));

    const fracTokenAddr = await vault.getNFTokenAddr(0);
    console.log(fracTokenAddr);
    const fracTokenContract = await NFToken.attach(
      fracTokenAddr
    );

    /*
      frac token supply and balance testing
    */
    expect((await fracTokenContract.totalSupply()) /10**18).to.equal(1000000);
    expect((await fracTokenContract.balanceOf(vault.address) ) / 10**18).to.equal(500000);
    expect((await fracTokenContract.balanceOf(owner.address) ) / 10**18).to.equal(500000);
    expect((await vault.getNFTokenBalance(tokenInternalId, vault.address)) / 10**18).to.equal(500000);
    expect((await vault.getNFTokenBalance(tokenInternalId, owner.address)) / 10**18).to.equal(500000);

    /*
      frac token buying 
    */
    await wEth.give(ethers.utils.parseUnits("1000000000000", 18));
    await wEth.approve(vault.address, ethers.utils.parseUnits("1000000000000", 18));
    await vault.buyTokensIndividual(tokenInternalId, ethers.utils.parseUnits("43", 18));
    expect(await wEth.balanceOf(owner.address) / 10**18).to.almost.equal(1000000000000 - 43);
    expect(await wEth.balanceOf(vault.address) / 10**18).to.almost.equal(43);
    expect(await fracTokenContract.balanceOf(owner.address) / 10**18).to.almost.equal(500000 + 43);
    expect(await fracTokenContract.balanceOf(vault.address) / 10**18).to.almost.equal(500000 - 43);

    /*
      frac token selling
    */
    await fracTokenContract.approve(vault.address, ethers.utils.parseUnits("1000000", 18))
    await vault.sellTokensIndividual(tokenInternalId, ethers.utils.parseUnits("20", 18));
    expect(await wEth.balanceOf(owner.address) / 10**18).to.almost.equal(1000000000000 - 43 + 20);
    expect(await wEth.balanceOf(vault.address) / 10**18).to.almost.equal(43 - 20);
    expect(await fracTokenContract.balanceOf(owner.address) / 10**18).to.almost.equal(500000 + 43 - 20);
    expect(await fracTokenContract.balanceOf(vault.address) / 10**18).to.almost.equal(500000 - 43 + 20);
  })

  it("Should deposit 5 NFT into vault and mint tokens into contract, create a bucket, and allow buying/selling of BUCK tokens", async function (){    
    const [owner] = await ethers.getSigners();

    const numNFTs = 5;  // Number of NFTs in buckets

    // NFT FRAC token info
    const mintSupply = 1000000;
    const tokenName = "Frac";
    const tokenTicker = "FRAC";
    const amountToKeep = 0;
    const tokenInternalId = 0;

    // console.log("Num NFTs: "+numNFTs)
    // Make 5 NFTS
    for(let i=0; i<numNFTs; i++){
      await minter.mint(owner.address);
      await minter.approve(vault.address, i+1);
      await minter.safeTransfer(owner.address, vault.address, i+1);
    }

    // Make sure all minted NFTs were successfully deposited to the vault
    expect(await vault.getNumberDepositedERC721s()).to.equal(5);
    
    // Mint FRAC tokens for each NFT deposited to the vault
    for(let i=0; i<numNFTs; i++){
      await vault.mintTokensForNFT(ethers.utils.parseUnits(String(mintSupply), 18), tokenName.concat(i), tokenTicker.concat(i), i, 0);
    }
    
    //Create a bucket with the 5 NFTS
    await buckets.createBucket([0,1,2,3,4], "Test Bucket 1", "TBUCK");

    expect(await buckets.getNumberBucketsCreated()).to.equal(1);  // Verify that bucket was created

    // Buy 5 bucket tokens
    const buyAmount = 5;
    // Verify prices
    expect(await vault.calculateAmountOfwEth(5, 0)).to.equal(5);
    expect(await buckets.calcBucketPrice(0, 5)).to.equal(25);
    

    await wEth.give(ethers.utils.parseUnits("1000000000000", 18));
    await wEth.approve(buckets.address, ethers.utils.parseUnits("1000000000000", 18));
    await buckets.buyBucket(0, ethers.utils.parseUnits(String(buyAmount), 18), owner.address);



    const buckTokenAddr = await buckets.getBuckTokenAddr(0);  //Get Bucket0 token address
    console.log(buckTokenAddr);
    const buckTokenContract = await NFToken.attach(
      buckTokenAddr
    );

    expect(await buckTokenContract.totalSupply()).to.equal(5);
    
    //expect(await buckTokenContract.balanceOf(owner.address)).to.equal(ethers.utils.parseUnits(String(buyAmount), 18));

    // for(let i=0; i<numNFTs; i++){
    //   const fracTokenAddr = await vault.getNFTokenAddr(i);
    //   const fracTokenContract = await NFToken.attach(
    //     fracTokenAddr
    //   );
    //   expect(await fracTokenContract.balanceOf(buckets.address)).to.equal(ethers.utils.parseUnits(String(buyAmount), 18));
    // }

})});
  