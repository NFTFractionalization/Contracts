const hre = require("hardhat");

async function main(){
    const rpc = await new hre.ethers.providers.JsonRpcProvider(process.env.RPC_PROVIDER)
    const owner = new hre.ethers.Wallet(process.env.PRIVATE_KEY0, rpc);

    await hre.run("compile");

    const Reciever = await hre.ethers.getContractFactory("XChainVault");
    //It probably wont be owner at the end of this.
    const reciever = await Reciever.deploy(owner.address);
    await reciever.deployed();

    console.log("XChain Reciever Up at: ", reciever.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });