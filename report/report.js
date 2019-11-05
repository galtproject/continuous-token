const MockFixedSupplyToken = artifacts.require('MockFixedSupplyToken.sol');
const BancorFormula = artifacts.require('./BancorFormula');
const EthToFixedSupplyDistributionFactory = artifacts.require('./EthToFixedSupplyDistributionFactory.sol');
const MockWETH9 = artifacts.require('MockWETH9.sol');
const ContinuousToken = artifacts.require('./ContinuousToken');

ContinuousToken.numberFormat = 'String';

const { web3 } = MockWETH9;

const fs = require('fs');
const { ether, gwei } = require('@galtproject/solidity-test-chest')(web3);

module.exports = async function(done) {
  try {
    await runReport();
  } catch (e) {
    console.error(e);
  }
  done();
};

async function runReport() {
  const accounts = await web3.eth.getAccounts();
  const [alice, bob, charlie, dan] = accounts;

  const debug = true;

  const gasPriceLimitValue = '22000000000';
  const converterMaxFee = '1000000';
  const fixedTotalSupply = 42 * 10 ** 6;

  // 20%
  const etherReserveRatio = 200 * 1000;
  const ethStart = 5;

  const iterations = 13;

  const bancorFormula = await BancorFormula.new();
  const factory = await EthToFixedSupplyDistributionFactory.new(ether(0.5), charlie, bancorFormula.address);

  const fixedToken = await MockFixedSupplyToken.new(alice, ether(fixedTotalSupply), 'ABC Token', 'ABC', 18, {
    from: alice
  });
  const weth = await MockWETH9.new();

  let res = await factory.build(
    weth.address,
    fixedToken.address,
    // reserve ratio 20%
    etherReserveRatio,
    // max exchange fee 5%
    converterMaxFee,
    // initial exchange fee 1%
    10 * 1000,
    // fee beneficiary
    bob,
    // initial supply beneficiary
    charlie,
    // initial supply amount
    ether(4200 * 1000),
    { value: ether(0.5) }
  );

  const continuousToken = await ContinuousToken.at(res.logs[2].args.continuousToken);

  await continuousToken.setGasPriceModifier(bob);
  await continuousToken.setGasPrice(gwei(30), { from: bob });

  await weth.deposit({ from: alice, value: ether(ethStart) });
  await weth.transfer(continuousToken.address, ether(ethStart), { from: alice });

  let csv = '';
  addLineToCsv(',,,');
  addLineToCsv(`ContinuousToken initial totalSupply,${fixedTotalSupply},,`);
  addLineToCsv(`ContinuousToken initial ETH balance,${ethStart},,`);
  addLineToCsv(',,,');
  addLineToCsv(`etherReserveRatio,${etherReserveRatio},,`);
  addLineToCsv(',,,');
  addLineToCsv('ethSpent,fixedReturn,fee,fixedPerEth,restFixed,fixedSoldPercent');

  await weth.deposit({ from: alice, value: ether(1000 * 1000) });

  await buyFixed(155);

  for (let i = 0; i < iterations; i++) {
    await buyFixed(1000);
    if (i > 100) {
      break;
    }
  }

  const aliceBalance = BigInt(await continuousToken.balanceOf(alice));

  // eslint-disable-next-line
  await buyEth(aliceBalance / 2n);
  // eslint-disable-next-line
  await buyEth(aliceBalance / 2n);
  await buyEth(await continuousToken.balanceOf(bob), bob);

  // final checks
  addLineToCsv(',,,');
  addLineToCsv(`Final ContinuousToken totalSupply,${await continuousToken.totalSupply()},,`);
  addLineToCsv(`Final ContinuousToken WETH balance,${await weth.balanceOf(continuousToken.address)},,`);
  addLineToCsv(`Final ContinuousToken Fixed balance,${await fixedToken.balanceOf(continuousToken.address)},,`);
  addLineToCsv(',,,');

  /**
   *
   * @param sendEth in ether
   * @returns {Promise<void>}
   */
  async function buyFixed(sendEth) {
    await weth.approve(continuousToken.address, ether(sendEth), { from: alice });
    const restFixed = fixedTotalSupply - weiToEtherRound(await continuousToken.totalSupply());
    res = await continuousToken.buy(ether(sendEth), 1, {
      from: alice,
      gasPrice: gasPriceLimitValue
    });
    const fixedLogOutput = weiToEtherRound(res.logs[3].args.purchaseReturn);
    const fixedFeeOutput = weiToEtherRound(res.logs[3].args.fee);
    const fixedPerEth = roundToPrecision(fixedLogOutput / sendEth);

    const fixedSoldPercent = ((fixedTotalSupply - restFixed) / fixedTotalSupply) * 100;

    addLineToCsv(`${sendEth.toFixed(2)},${fixedLogOutput},${fixedFeeOutput},${fixedPerEth},${restFixed},${fixedSoldPercent.toFixed(2)}`);
  }

  /**
   *
   * @param sendContinuous in wei!!!
   * @param from address
   * @returns {Promise<void>}
   */
  async function buyEth(sendContinuous, from = alice) {
    sendContinuous = sendContinuous.toString();
    const restFixed = fixedTotalSupply - weiToEtherRound(await continuousToken.totalSupply());
    res = await continuousToken.sell(sendContinuous, 1, {
      from,
      gasPrice: gasPriceLimitValue
    });
    const ethReturn = weiToEtherRound(res.logs[3].args.saleReturn);
    const ethFee = weiToEtherRound(res.logs[3].args.fee);
    const ethPerContinuous = roundToPrecision(weiToEtherRound(sendContinuous) / ethReturn);

    const fixedSoldPercent = ((fixedTotalSupply - restFixed) / fixedTotalSupply) * 100;

    addLineToCsv(`${weiToEtherRound(sendContinuous).toFixed(2)},${ethReturn},${ethFee},${ethPerContinuous},${restFixed},${fixedSoldPercent.toFixed(2)}`);
  }

  function addLineToCsv(str) {
    csv += `${str}\n`;
    if (debug) {
      console.log(str);
    }
  }

  function roundToPrecision(number, precision = 4) {
    return Math.round(number * 10 ** precision) / 10 ** precision;
  }

  function weiToEtherRound(wei, precision = 4) {
    return roundToPrecision(parseFloat(web3.utils.fromWei(wei, 'ether')), precision);
  }

  fs.writeFileSync(`${__dirname}/EthToFixed.csv`, csv);
}
