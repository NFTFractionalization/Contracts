require("@nomiclabs/hardhat-waffle");
require('@openzeppelin/hardhat-upgrades');
require('hardhat-contract-sizer');
require('dotenv').config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.4",
  networks:{
    hardhat:{
    },
    localhost:{
      "url": "http://127.0.0.1:8545/",
      accounts: [process.env.PRIVATE_KEY0, process.env.PRIVATE_KEY1]
    },
    mumbai:{
      "url":"https://rpc-mumbai.maticvigil.com",
      accounts:[process.env.METAMASK_PK0, process.env.METAMASK_PK1]
    },
    avalanche:{
      "url":"https://api.avax-test.network/ext/bc/C/rpc",
      accounts:[process.env.METAMASK_PK0, process.env.METAMASK_PK1]
    },
    bsctestnet: {
      "url":"https://data-seed-prebsc-1-s1.binance.org:8545",
      accounts:[process.env.METAMASK_PK0, process.env.METAMASK_PK1],
      gas: 2100000,
      gasPrice: 8000000000
    }
  }
};
