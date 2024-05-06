require("@nomiclabs/hardhat-waffle");
require("dotenv").config();

module.exports = {
  solidity: "0.8.20",
  networks: {
    mainnet: {
      url: process.env.MAINNET_URL,
      accounts: [`0x${process.env.PRIVATE_KEY}`]
    }
  }
};