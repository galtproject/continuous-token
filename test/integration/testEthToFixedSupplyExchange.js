const EthToFixedSupplyDistributionFactory = artifacts.require('./EthToFixedSupplyDistributionFactory.sol');
const MockFixedSupplyToken = artifacts.require('./MockFixedSupplyToken');
const BancorFormula = artifacts.require('./BancorFormula');
const Converter = artifacts.require('./Converter');
const MockWETH9 = artifacts.require('./MockWETH9');
const ContinuousToken = artifacts.require('./ContinuousToken');
const EthToFixedSupplyExchange = artifacts.require('./EthToFixedSupplyExchange.sol');

EthToFixedSupplyExchange.numberFormat = 'String';
MockFixedSupplyToken.numberFormat = 'String';
ContinuousToken.numberFormat = 'String';
MockWETH9.numberFormat = 'String';
Converter.numberFormat = 'String';
BancorFormula.numberFormat = 'String';

const { web3 } = MockFixedSupplyToken;

const { ether, gwei } = require('@galtproject/solidity-test-chest')(web3);

let weth;
let fixedToken;
let factory;

contract('EthToFixedSupplyExchange', accounts => {
  const [alice, bob, charlie, dan, eve] = accounts;

  describe('ethToFixedToken', () => {
    before(async function() {
      const bancorFormula = await BancorFormula.new();
      factory = await EthToFixedSupplyDistributionFactory.new(ether(0.5), eve, bancorFormula.address);
    });

    beforeEach(async function() {
      weth = await MockWETH9.new();
      fixedToken = await MockFixedSupplyToken.new(dan, ether(42 * 1000), 'ABC Token', 'ABC', 18);
    });

    it('should return foo', async function() {
      let res = await factory.build(
        weth.address,
        fixedToken.address,
        // reserve ratio 20%
        200 * 1000,
        // max exchange fee 5%
        50 * 1000,
        // initial exchange fee 1%
        10 * 1000,
        // fee beneficiary
        bob,
        // initial supply beneficiary
        charlie,
        // initial supply amount
        ether(1),
        { value: ether(0.5) }
      );

      const converter = await Converter.at(res.logs[2].args.converter);
      const continuousToken = await ContinuousToken.at(res.logs[2].args.continuousToken);
      const exchange = await EthToFixedSupplyExchange.at(res.logs[2].args.ethToFixedSupplyExchange);

      continuousToken.setGasPriceModifier(bob);
      continuousToken.setGasPrice(gwei(30), { from: bob });

      await fixedToken.transfer(converter.address, ether(42 * 1000), { from: dan });

      await weth.deposit({ from: alice, value: ether(99) });
      await weth.transfer(continuousToken.address, ether(99), { from: alice });

      assert.equal(await continuousToken.totalSupply(), ether(1));
      assert.equal(await weth.balanceOf(continuousToken.address), ether(99));
      assert.equal(await continuousToken.balanceOf(converter.address), ether(0));
      assert.equal(await fixedToken.balanceOf(converter.address), ether(42 * 1000));

      const ret = '13620049550887141';

      // convert eth -> fixed

      res = await exchange.ethToFixed(1, { from: alice, value: ether(7) });

      assert.equal((await continuousToken.totalSupply()) > ether(1), true);
      assert.equal(await weth.balanceOf(continuousToken.address), ether(99 + 7));
      assert.equal(await continuousToken.balanceOf(converter.address), ret);
      // commission
      assert.equal(await continuousToken.balanceOf(bob), 137576258089770);
      assert.equal(await fixedToken.balanceOf(converter.address), 41999986379950449112859);

      // convert back

      await fixedToken.approve(exchange.address, ret, { from: alice });
      await exchange.fixedToEth(ret, 1, { from: alice });
      await fixedToken.approve(continuousToken.address, '137576258089770', { from: bob });
      await continuousToken.sell('137576258089770', 1, { from: bob });

      assert.equal(await continuousToken.balanceOf(converter.address), ether(0));
      assert.equal(await fixedToken.balanceOf(converter.address), ether(42 * 1000));
    });
  });
});
