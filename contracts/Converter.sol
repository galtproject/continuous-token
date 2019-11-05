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
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Helpers.sol";
import "./interfaces/IConverter.sol";


contract Converter is IConverter {
  event Convert1to2(address indexed sender, uint256 amount);
  event Convert2to1(address indexed sender, uint256 amount);

  IERC20 public token1;
  IERC20 public token2;

  constructor(address _token1, address _token2) public {
    token1 = IERC20(_token1);
    token2 = IERC20(_token2);
  }

  function convert1to2(uint256 _amount) external {
    require(token2.balanceOf(address(this)) >= _amount, "Not enough funds on converter");

    Helpers.ensureTransferFrom(token1, msg.sender, address(this), _amount);
    Helpers.ensureTransfer(token2, msg.sender, _amount);

    emit Convert1to2(msg.sender, _amount);
  }

  function convert2to1(uint256 _amount) external {
    require(token1.balanceOf(address(this)) >= _amount, "Not enough funds on converter");

    Helpers.ensureTransferFrom(token2, msg.sender, address(this), _amount);
    Helpers.ensureTransfer(token1, msg.sender, _amount);

    emit Convert2to1(msg.sender, _amount);
  }
}
