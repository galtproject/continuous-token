/*
 * Copyright ©️ 2018 Galt•Project Society Construction and Terraforming Company
 * (Founded by [Nikolai Popeka](https://github.com/npopeka)
 *
 * Copyright ©️ 2018 Galt•Core Blockchain Company
 * (Founded by [Nikolai Popeka](https://github.com/npopeka) by
 * [Basic Agreement](ipfs/QmaCiXUmSrP16Gz8Jdzq6AJESY1EAANmmwha15uR3c1bsS)).
 */
pragma solidity ^0.5.10;


contract IWETH9 {
  function balanceOf(address) external view returns (uint256);
  function allowance(address, address) external view returns (uint256);
  function deposit() external payable;
  function withdraw(uint256) external;
  function totalSupply() external view returns (uint256);
  function approve(address guy, uint256 wad) external returns (bool);
  function transfer(address dst, uint256 wad) external returns (bool);
  function transferFrom(address src, address dst, uint wad) external returns (bool);
}
