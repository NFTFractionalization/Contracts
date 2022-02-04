const hre = require("hardhat");

async function main(){

    const rpc = await new hre.ethers.providers.JsonRpcProvider(process.env.RPC_PROVIDER)
    const owner = new hre.ethers.Wallet(process.env.PRIVATE_KEY0, rpc);

    const Reciever = await hre.ethers.getContractFactory("XChainVault");
    const reciever = await Reciever.attach(
        "0x5FbDB2315678afecb367f032d93F642f64180aa3"
    );

    const Minter = await hre.ethers.getContractFactory("Minter");
    const minter = await Minter.deploy();
    await minter.deployed();

    await minter.mint(owner.address);
    console.log("Deployed new contract addr and minted");

    const ownerBal1 = await minter.balanceOf(owner.address);
    console.log("Owner holds "+ownerBal1);

    console.log("Transfering...");

    await minter.safeTransfer(owner.address, reciever.address, 1);

    const ownerBal2 = await minter.balanceOf(owner.address);
    console.log("Owner holds " + ownerBal2);

    const recieverBal = await minter.balanceOf(reciever.address);
    console.log("Reciever holds "+recieverBal);

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
    console.error(error);
    process.exit(1);
});