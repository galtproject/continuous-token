/*
 * Copyright ©️ 2018 Galt•Project Society Construction and Terraforming Company
 * (Founded by [Nikolai Popeka](https://github.com/npopeka)
 *
 * Copyright ©️ 2018 Galt•Core Blockchain Company
 * (Founded by [Nikolai Popeka](https://github.com/npopeka) by
 * [Basic Agreement](ipfs/QmaCiXUmSrP16Gz8Jdzq6AJESY1EAANmmwha15uR3c1bsS)).
 */
pragma solidity ^0.5.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";


contract MockFixedSupplyToken is ERC20, ERC20Detailed {
  constructor(
    address _initialSupplyHolder,
    uint256 _initialSupply,
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  )
    public
    ERC20Detailed(_name, _symbol, _decimals)
  {
    _mint(_initialSupplyHolder, _initialSupply);
  }
}
