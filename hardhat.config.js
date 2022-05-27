/**
 * @type import('hardhat/config').HardhatUserConfig
 */
 require('@nomiclabs/hardhat-ethers')
 require('@nomiclabs/hardhat-waffle')
 
 require('dotenv').config();

const privateKey = process.env.PRIVATE_KEY
const endpoint = process.env.URL;
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.0",
      },
      {
        version: "0.8.1",
      },
    ],
  },
  networks: {
    localhost: {
      url: endpoint,
      accounts: [`0x${privateKey}`]
    },
    rinkeby: {
      url: endpoint,
      accounts: [`0x${privateKey}`]
    }
  }
};
