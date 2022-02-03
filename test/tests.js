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

    //Before runs before all tests in the file
    before(async function(){
      
      const Minter = await ethers.getContractFactory("Minter");
      minter = await Minter.deploy();
      await minter.deployed();

      const Vault = await ethers.getContractFactory("Vault");
      vault = await Vault.deploy();
      await vault.deployed();
    });

    it("Should mint new NFT", async function () {
      const [owner] = await ethers.getSigners();
      
      const mintTx = await minter.mint(owner.address);

      const ownerNFTBalance = await minter.balanceOf(owner.address);

      expect(ownerNFTBalance).to.equal(1);
    })

    it("Should deposit NFT into vault", async function (){    
    
      
    })
  })
});
