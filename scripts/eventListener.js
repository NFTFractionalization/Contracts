const hre = require("hardhat");
const fs = require("fs");
const { Contract } = require("@ethersproject/contracts");

function readShittyDB(){
    let rawdata = fs.readFileSync('shittyDB.json');
    let shittyJson = JSON.parse(rawdata);
    return shittyJson;
}

function writeShittyDB(bscLastBlock, bscProcessed, maticLastBlock, maticProcessed){

    let shittyJson = {
        bscLastBlock: bscLastBlock,
        bscProcessed: bscProcessed,
        maticLastBlock: maticLastBlock,
        maticProcessed: maticProcessed
    }

    let data = JSON.stringify(shittyJson);
    fs.writeFileSync('shittyDB.json', data);
}

function readJson(json){
    let rawdata = fs.readFileSync(json);
    let shittyJson = JSON.parse(rawdata);
    return shittyJson;
}

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}
class nftObj{
    constructor(from, tokenId, internalId, nftAddr, txHash, chainId){
        this.from = from;
        this.tokenId = tokenId;
        this.xChainInternalId = internalId;
        this.nftAddr = nftAddr;
        this.txHash = txHash;
        this.chainId = chainId;
    }
}

async function main(){

    async function getXChainRecieved(startBlock, endBlock){
        let filter = Reciever.filters.XChainRecieved();

        let events = await Reciever.queryFilter(filter, startBlock, endBlock);
        return events;
    }

    async function getXChainRelease(startBlock, endBlock){
        let filter = Vault.filters.XChainRelease();

        let events = await Vault.queryFilter(filter, startBlock, endBlock);
        return events;
    }

    async function processXChainRecieved(recieved){
        console.log("Processing... "+recieved.txHash);

        console.log("Recieved.From: "+recieved.from+ " Recieved.TokenId: "+recieved.tokenId+" Recieved.InternalId: "+recieved.xChainInternalId+" Recieved.NFTAddr: "+recieved.nftAddr+" Recieved.ChainId: "+recieved.chainId)
        await Vault.registerXChainNFT(recieved.from, recieved.tokenId, recieved.xChainInternalId, recieved.nftAddr, recieved.chainId);

        bscProcessed.push(recieved.txHash);
    }

    async function processXChainRelease(nft){
        console.log("Releasing... "+nft.txHash);

        console.log("NFT.From: "+nft.from+ " NFT.TokenId: "+nft.tokenId+" NFT.InternalId: "+nft.xChainInternalId+" NFT.NFTAddr: "+nft.nftAddr+" NFT.ChainId: "+nft.chainId)
        
        let increaseGas = {gasPrice: 8000000000, gasLimit: 3000000}
        
        await Reciever.releaseNFT(nft.from, nft.xChainInternalId, increaseGas);

        maticProcessed.push(nft.txHash);
    }

    
    

    const matic_rpc = new hre.ethers.providers.JsonRpcProvider(process.env.MATIC_RPC_PROVIDER);
    const matic_wallet = new hre.ethers.Wallet(process.env.METAMASK_PK0, matic_rpc);

    const bsc_rpc = new hre.ethers.providers.JsonRpcProvider(process.env.BSC_RPC_PROVIDER);
    const bsc_wallet = new hre.ethers.Wallet(process.env.METAMASK_PK0, bsc_rpc);

    xChainVaultABI = readJson("xChainVaultABI.json");
    const recieverAddr = "0xeC3676Ca25d450E0F799bAD6324274fBB59f8494";
    const Reciever = new Contract(recieverAddr, xChainVaultABI, bsc_wallet);

    VaultABI = readJson("VaultABI.json");
    const vaultAddr = "0xb7Fa8640CAEf4b244398Af50be2cF62BD1cfbDaB";
    const Vault = new Contract(vaultAddr, VaultABI, matic_wallet);

    console.log("Listener connected to: ", Reciever.address);
    console.log("Calls made to: "+Vault.address);
    
    const shittyJson = readShittyDB();
    
    let bscStartBlock = shittyJson.bscLastBlock;
    let maticStartBlock = shittyJson.maticLastBlock;
    
    let bscProcessed = Array.from(shittyJson.bscProcessed);
    let maticProcessed = Array.from(shittyJson.maticProcessed);
    console.log("bscProcessedStartLength: "+bscProcessed.length);
    console.log("maticProcessedStartLength: "+maticProcessed.length);

    while(true){

        await sleep(5000);
        let bscEndBlock = await bsc_rpc.getBlockNumber();
        let maticEndBlock = await matic_rpc.getBlockNumber();

        console.log("bscStartBlock:" + bscStartBlock);
        console.log("bscEndBlock: " + bscEndBlock);

        let recievedEvents = await getXChainRecieved(bscStartBlock, bscEndBlock);

        if(recievedEvents.length >= 0 && bscStartBlock != bscEndBlock){           
            for(let i=0; i<recievedEvents.length; i++){
                let txHash = recievedEvents[i].transactionHash;
                if(!bscProcessed.includes(txHash)){
                    console.log("Processing Recieved Tx");
                    let args = recievedEvents[i].args;
                    console.log(args);
                    let recieved = new nftObj(args.from, args.tokenId, args.xChainInternalId, args.nftAddr, txHash, args.chainId);
                    
                    await processXChainRecieved(recieved);
                }
            }
        }
        else{
            console.log("No BSC Events Recieved");
        }

        console.log("maticStartBlock:" + maticStartBlock);
        console.log("maticEndBlock: " + maticEndBlock);

        let releaseEvents = await getXChainRelease(maticStartBlock, maticEndBlock);

        if(releaseEvents.length >= 0 && maticStartBlock != maticEndBlock){           
            for(let i=0; i<releaseEvents.length; i++){
                let txHash = releaseEvents[i].transactionHash;
                if(!maticProcessed.includes(txHash)){
                    console.log("Processing Release Tx");
                    let args = releaseEvents[i].args;
                    console.log(args);
                    let release = new nftObj(args.to, args.tokenId, args.xChainInternalId, args.nftAddr, txHash, args.chainId);
                    
                    await processXChainRelease(release);
                }
            }
        }            

        else{
            console.log("No Matic Events Recieved");
        }

        writeShittyDB(bscEndBlock, bscProcessed, maticEndBlock, maticProcessed);

        bscStartBlock = bscEndBlock;
        maticStartBlock = maticEndBlock;

    }

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });