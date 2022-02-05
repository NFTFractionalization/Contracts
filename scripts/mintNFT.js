const hre = require("hardhat");

async function main(){

    const rpc = await new hre.ethers.providers.JsonRpcProvider(process.env.BSC_RPC_PROVIDER)
    const owner = new hre.ethers.Wallet(process.env.METAMASK_PK0, rpc);

    console.log("Owner Address: "+owner.address)

    const Reciever = await hre.ethers.getContractFactory("XChainVault");
    const reciever = await Reciever.attach(
        "0xeC3676Ca25d450E0F799bAD6324274fBB59f8494"
    );

    const Minter = await hre.ethers.getContractFactory("Minter");
    const minter = await Minter.attach(
        "0x04eE2d0202D2124ba2a43720544ed35F21bb16D2"
    );

    const txHash = await minter.mint(owner.address);
    console.log(txHash);

    const ownerBal1 = await minter.balanceOf(owner.address);
    console.log("Owner holds "+ownerBal1);
    
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
    console.error(error);
    process.exit(1);
});