/*
 * Copyright ©️ 2018 Galt•Project Society Construction and Terraforming Company
 * (Founded by [Nikolai Popeka](https://github.com/npopeka)
 *
 * Copyright ©️ 2018 Galt•Core Blockchain Company
 * (Founded by [Nikolai Popeka](https://github.com/npopeka) by
 * [Basic Agreement](ipfs/QmaCiXUmSrP16Gz8Jdzq6AJESY1EAANmmwha15uR3c1bsS)).
 */
pragma solidity ^0.5.10;


contract IConverter {
  event Convert1to2(address indexed sender, uint256 amount);
  event Convert2to1(address indexed sender, uint256 amount);

  function convert1to2(uint256 _amount) external;
  function convert2to1(uint256 _amount) external;
}
