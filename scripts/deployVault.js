const hre = require("hardhat");

async function main(){
    const rpc = await new hre.ethers.providers.JsonRpcProvider(process.env.MUMBAI_RPC_PROVIDER)
    const owner = new hre.ethers.Wallet(process.env.METAMASK_PK0, rpc);

    console.log("Owner Address: "+owner.address);

    await hre.run("compile");

    const wEth = await hre.ethers.getContractFactory("wEth");
    const weth = await wEth.deploy(ethers.utils.parseUnits("1000000000000", 18));
    await weth.deployed();

    const Vault = await hre.ethers.getContractFactory("Vault");
    const vault = await Vault.deploy(weth.address, owner.address);
    await vault.deployed();

    console.log("Vault Up at: " + vault.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });