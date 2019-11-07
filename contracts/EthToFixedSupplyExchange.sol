/*
 * Copyright ©️ 2018 Galt•Project Society Construction and Terraforming Company
 * (Founded by [Nikolai Popeka](https://github.com/npopeka)
 *
 * Copyright ©️ 2018 Galt•Core Blockchain Company
 * (Founded by [Nikolai Popeka](https://github.com/npopeka) by
 * [Basic Agreement](ipfs/QmaCiXUmSrP16Gz8Jdzq6AJESY1EAANmmwha15uR3c1bsS)).
 */
pragma solidity ^0.5.10;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./interfaces/IContinuousToken.sol";
import "./interfaces/IConverter.sol";
import "./interfaces/IWETH.sol";


contract EthToFixedSupplyExchange {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event EthToFixed(address indexed from, uint256 ethAmount, uint256 fixedAmount);
  event FixedToEth(address indexed from, uint256 ethAmount, uint256 fixedAmount);

  IContinuousToken public continuousToken;
  IERC20 public fixedSupplyToken;
  IWETH9 public weth;
  IConverter public converter;

  constructor (
    address _continuousToken,
    address _fixedSupplyToken,
    address _weth,
    address _converter
  ) public {
    continuousToken = IContinuousToken(_continuousToken);
    fixedSupplyToken = IERC20(_fixedSupplyToken);
    weth = IWETH9(_weth);
    converter = IConverter(_converter);
  }

  /**
   * @dev Executes full conversion cycle with the following steps:
   * - accepts ETH from msg.sender
   * - wraps ETH into WETH
   * - buys ContinuousTokens with WETH at ContinuousToken contract
   * - converts ContinuousTokens to FixedSupplyTokens at Converter
   * - transfers FixedSupplyTokens back to msg.sender
   */
  function ethToFixed(uint256 _minReturn) external payable returns (uint256 amount, uint256 feeAmount) {
    uint256 ethAmount = msg.value;
    require(ethAmount > 0, "Require msg.value > 0");

    // eth -> weth
    weth.deposit.value(ethAmount)();

    // weth -> continuousToken
    weth.approve(address(continuousToken), ethAmount);
    (amount, feeAmount) = continuousToken.buy(ethAmount, _minReturn);

    // continuousToken -> fixedSupplyToken
    // converter token #1 - fixedSupplyToken
    // converter token #2 - continuousToken
    continuousToken.approve(address(converter), amount);
    converter.convert2to1(amount);

    // fixed -> msg.sender
    fixedSupplyToken.transfer(msg.sender, amount);

    emit EthToFixed(msg.sender, ethAmount, amount);
  }

  function fixedToEth(uint256 _sellAmount, uint256 _minReturn) external returns (uint256 amount, uint256 feeAmount) {
    require(_sellAmount > 0, "Require _sellAmount > 0");

    // fixed transfer msg.sender -> exchange
    fixedSupplyToken.transferFrom(msg.sender, address(this), _sellAmount);

    // fixedSupplyToken -> continuousToken
    // converter token #1 - fixedSupplyToken
    // converter token #2 - continuousToken
    fixedSupplyToken.approve(address(converter), _sellAmount);
    converter.convert1to2(_sellAmount);

    (amount, feeAmount) = continuousToken.sell(_sellAmount, _minReturn);

    // weth -> eth
    weth.withdraw(amount);

    // eth -> msg.sender
    msg.sender.transfer(amount);

    emit FixedToEth(msg.sender, amount, _sellAmount);
  }

  function() external payable {
    // TODO: check for istanbul compatibility
    require(msg.sender == address(weth), "Only etherToken can send value");
  }
}
