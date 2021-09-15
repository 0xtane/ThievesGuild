require("@nomiclabs/hardhat-waffle");

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
   solidity: {
     compilers: [
       {
         version: "0.8.3",
         settings: {
           optimizer: {
             enabled: true,
             runs: 200,
           },
         },
       },
       {
         version: "0.8.7",
         settings: {
           optimizer: {
             enabled: true,
             runs: 200,
           },
         },
       },
     ],
   },
   networks: {
     fantom: {
         url: "https://rpcapi.fantom.network",
         accounts: [`0x3f460b5cee36c9071df1237ba78a6e83ef74758d324a8f4d0228dc9f1fd1bbaf`],
       },
   },
   etherscan: {
     apiKey: "VNTKV4NEBMFZT8FTMUS86HDXPWEKZY3NEA"
   }
 }
