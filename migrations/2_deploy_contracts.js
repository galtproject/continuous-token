const BancorFormula = artifacts.require('BancorFormula');
const EthToFixedSupplyDistributionFactory = artifacts.require('EthToFixedSupplyDistributionFactory');

const { ether } = require('@galtproject/solidity-test-chest')(web3);

module.exports = async function(deployer, network, accounts) {
  if (network === 'test') {
    console.log('Skipping migrations');
    return;
  }

  // WARNING: set fee beneficiary here instead of accounts[0]
  const feeBeneficiary = accounts[0];
  const feeValue = ether(0.5);
  // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

  let bancorFormulaAddress;

  if (network === 'mainnet') {
    // https://etherscan.io/address/0xffd2de852b694f88656e91d9defa6b425c454742#code
    bancorFormulaAddress = '0xffd2de852b694f88656e91d9defa6b425c454742';
  } else {
    const bancorFormula = await BancorFormula.new();
    bancorFormulaAddress = bancorFormula.address;
  }

  await deployer.deploy(EthToFixedSupplyDistributionFactory, feeValue, feeBeneficiary, bancorFormulaAddress);
};
