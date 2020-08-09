var HDWalletProvider = require("truffle-hdwallet-provider");

var mnemonic = '';

module.exports = {
  networks: {
    development: {
      host: '127.0.0.1',
      port: 9545,
      network_id: '*' // Match any network id
    },
    rinkeby: {
      network_id: 4,
      from: "0x2858b141429244dda03354aa35f1cc761a058a34",
      gas: 6712390,
      gasPrice: 20000000000, // 20 GWei
      provider: function() {
        return new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/v3/376e0f1d1aa842a0b7252e98ec97fb64");
      },
    },
    ropsten: {
      network_id: 3,
      from: "0x2858b141429244dda03354aa35f1cc761a058a34",
      gas: 6712390,
      gasPrice: 20000000000, // 20 GWei
      provider: function() {
        return new HDWalletProvider(mnemonic, "https://ropsten.infura.io/v3/376e0f1d1aa842a0b7252e98ec97fb64");
      },
    }
  },
  compilers: {
    solc: {
      version: ">0.5.0 <0.7.0", // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
      // settings: {          // See the solidity docs for advice about optimization and evmVersion
      //  optimizer: {
      //    enabled: false,
      //    runs: 200
      //  },
      //  evmVersion: "byzantium"
      // }
    },
  },
};
