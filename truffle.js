const Ganache = require('ganache-core');

const config = {
  networks: {
    local: {
      host: '127.0.0.1',
      port: 8545,
      network_id: '*'
    },
    test: {
      // https://github.com/trufflesuite/ganache-core#usage
      provider: Ganache.provider({
        unlocked_accounts: [0, 1, 2, 3, 4, 5],
        total_accounts: 30,
        debug: true,
        vmErrorsOnRPCResponse: true,
        default_balance_ether: 5000000,
        // 7 800 000
        gasLimit: 0x7704c0
      }),
      skipDryRun: true,
      network_id: '*'
    }
  },
  compilers: {
    solc: {
      version: 'native',
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      },
      evmVersion: 'petersburg'
    }
  }
};

if (process.env.SOLIDITY_COVERAGE === 'yes') {
  delete config.networks.test;
}

module.exports = config;
