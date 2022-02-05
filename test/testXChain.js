/*const { expect } = require("chai");
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
    var xchainvault;

    beforeEach(async function(){
      const [owner] = await ethers.getSigners();
      NFToken = await ethers.getContractFactory("NFToken");

      const WEth = await ethers.getContractFactory("wEth");
      wEth = await WEth.deploy(1000000);
      await wEth.deployed();
      
      const Minter = await ethers.getContractFactory("Minter");
      minter = await Minter.deploy();
      await minter.deployed();

      const Vault = await ethers.getContractFactory("Vault");
      vault = await Vault.deploy(wEth.address, owner.address);
      await vault.deployed();

      const XChainVault = await ethers.getContractFactory("XChainVault");
      xchainvault = await XChainVault.deploy(owner.address, 1);
      await xchainvault.deployed();

    });

    it("Should mint new NFT", async function () {
      const [owner] = await ethers.getSigners();
      
      const mintTx = await minter.mint(owner.address);

      const ownerNFTBalance = await minter.balanceOf(owner.address);

      expect(ownerNFTBalance).to.equal(1);
    })

    it("Should deposit NFT into vault and mint tokens into contract", async function (){    
      const [owner] = await ethers.getSigners();

      const tokenId = await minter.mint(owner.address);
      
      const ownerNFTBalance = await minter.balanceOf(owner.address);
      expect(ownerNFTBalance).to.equal(1);

      await minter.approve(vault.address, 1)
      
      await expect(await minter.safeTransfer(owner.address, xchainvault.address, 1))
      .to.emit(xchainvault, "XChainRecieved")
      .withArgs(owner.address, 1, 0, minter.address, 1);

      expect(await xchainvault.getNumberDepositedERC721s()).to.equal(1);
      
      
    })
  })
});*/
