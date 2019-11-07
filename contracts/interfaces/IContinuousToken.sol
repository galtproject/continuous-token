/*
 * Copyright ©️ 2018 Galt•Project Society Construction and Terraforming Company
 * (Founded by [Nikolai Popeka](https://github.com/npopeka)
 *
 * Copyright ©️ 2018 Galt•Core Blockchain Company
 * (Founded by [Nikolai Popeka](https://github.com/npopeka) by
 * [Basic Agreement](ipfs/QmaCiXUmSrP16Gz8Jdzq6AJESY1EAANmmwha15uR3c1bsS)).
 */

pragma solidity ^0.5.10;


contract IContinuousToken {
  // IERC20 events
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  // Token-specific events
  event SetConversionFee(uint256 conversionFee);
  event SetFeeBeneficiary(address feeBeneficiary);
  event SetGasLimit(uint256 gasLimit);
  event SetGasPriceModifier(address gasPriceModifier);
  event Buy(address indexed trader, uint256 reserveAmount, uint256 purchaseReturn, uint256 fee);
  event Sell(address indexed trader, uint256 continuousAmount, uint256 saleReturn, uint256 fee);
  event PriceUpdate(uint256 totalSupply, uint256 reserveBalance);

  // IERC20 methods
  function approve(address spender, uint256 amount) external returns (bool);

  // Token-specific methods
  function buy(uint256 _depositAmount, uint256 _minReturn) external returns (uint256 amount, uint256 feeAmount);
  function sell(uint256 _sellAmount, uint256 _minReturn) external returns (uint256 amount, uint256 feeAmount);
  function getPurchaseReturn(uint256 _depositAmount) external view returns (uint256, uint256);
  function getSaleReturn(uint256 _sellAmount) external view returns (uint256, uint256);
  function getFinalAmount(uint256 _amount, uint8 _magnitude) external view returns (uint256);
  function getReserveBalance() external view returns (uint256);
}
