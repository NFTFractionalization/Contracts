const { expect } = require("chai");
const { ethers } = require("hardhat");

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
  });

  //https://hardhat.org/tutorial/testing-contracts.html tutorial for testing!

  describe("Vault Tests", function() {
    var minter;
    var vault;
    var wEth;
    var NFToken;

    beforeEach(async function(){
      NFToken = await ethers.getContractFactory("NFToken");

      const WEth = await ethers.getContractFactory("wEth");
      wEth = await WEth.deploy(1000000);
      await wEth.deployed();
      
      const Minter = await ethers.getContractFactory("Minter");
      minter = await Minter.deploy();
      await minter.deployed();

      const Vault = await ethers.getContractFactory("Vault");
      vault = await Vault.deploy(wEth.address);
      await vault.deployed();
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
      
      await vault.mintTokensForNFT(mintSupply, tokenName, tokenTicker, tokenInternalId, amountToKeep);

      const fracTokenAddr = await vault.getNFTokenAddr(0);
      const fracTokenContract = await NFToken.attach(
        fracTokenAddr
      );

      expect(fracTokenContract.balanceOf(vault.address));

    })
  })
});
