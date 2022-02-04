const hre = require("hardhat");

async function main(){
    const rpc = await new hre.ethers.providers.JsonRpcProvider(process.env.RPC_PROVIDER)
    const owner = new hre.ethers.Wallet(process.env.PRIVATE_KEY0, rpc);

    console.log("Owner Address: "+owner.address);

    await hre.run("compile");

    const wEth = await hre.ethers.getContractFactory("wEth");
    const weth = await wEth.deploy(ethers.utils.parseUnits("1000000000000", 18));
    await weth.deployed();

    const Reciever = await hre.ethers.getContractFactory("XChainVault");
    //It probably wont be owner at the end of this.
    const reciever = await Reciever.deploy(owner.address, "Ethereum");
    await reciever.deployed();

    const Vault = await hre.ethers.getContractFactory("Vault");
    const vault = await Vault.deploy(weth.address, owner.address);
    await vault.deployed();

    console.log("XChain Reciever Up at: ", reciever.address);
    console.log("Vault Up at: " + vault.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });