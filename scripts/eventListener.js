const hre = require("hardhat");
const fs = require("fs");

function readShittyDB(){
    let rawdata = fs.readFileSync('shittyDB.json');
    let shittyJson = JSON.parse(rawdata);
    return shittyJson;
}

function writeShittyDB(lastBlock, processed){

    let shittyJson = {
        lastBlock: lastBlock,
        processed: processed
    }

    let data = JSON.stringify(shittyJson);
    fs.writeFileSync('shittyDB.json', data);
}

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}
class recievedObj{
    constructor(from, tokenId, internalId, nftAddr, txHash, chain){
        this.from = from;
        this.tokenId = tokenId;
        this.internalId = internalId;
        this.nftAddr = nftAddr;
        this.txHash = txHash;
        this.chain = chain;
    }
}

async function main(){

    async function getXChainRecieved(startBlock, endBlock){
        let filter = reciever.filters.XChainRecieved();

        let events = await reciever.queryFilter(filter, startBlock, endBlock);
        return events;
    }

    async function processEvent(recieved){
        console.log("Processing... "+recieved.txHash);

        vault.

        processed.push(recieved.txHash);
    }

    const rpc = await new hre.ethers.providers.JsonRpcProvider(process.env.RPC_PROVIDER)
    const owner = new hre.ethers.Wallet(process.env.PRIVATE_KEY0, rpc);

    await hre.run("compile");

    const Reciever = await hre.ethers.getContractFactory("XChainVault");
    //It probably wont be owner at the end of this.
    const reciever = await Reciever.attach(
        "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"
    );

    const Vault = await hre.ethers.getContractFactory("Vault");

    const vault = await Vault.attach(
        "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"
    );


    console.log("Listener connected to: ", reciever.address);
    
    const shittyJson = readShittyDB();
    
    let startBlock = shittyJson.lastBlock;
    
    let processed = Array.from(shittyJson.processed);
    console.log("ProcessedStartLength: "+processed.length);

    while(true){

        await sleep(5000);
        const endBlock = await rpc.getBlockNumber();

        console.log("StartBlock:" + startBlock);
        console.log("EndBlock: " + endBlock);

        let events = await getXChainRecieved(startBlock, endBlock);

        if(events.length >= 0 && startBlock != endBlock){
\            
            for(let i=0; i<events.length; i++){
                let txHash = events[i].transactionHash;
                if(!processed.includes(txHash)){
                    console.log("Processing Tx");
                    let args = events[i].args;
                    let recieved = new recievedObj(args.from, args.tokenId, args.internalId, args.nftAddr, txHash, args.chain);
                    
                    await processEvent(recieved);
                }
            }

            writeShittyDB(endBlock, processed);

            

        }
        else{
            console.log("No New Events Recieved");
        }

        startBlock = endBlock;

    }

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });