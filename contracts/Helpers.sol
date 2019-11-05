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


library Helpers {
  function ensureTransferFrom(IERC20 _token, address _from, address _to, uint256 _amount) internal {
    require(
      _token.transferFrom(_from, _to, _amount) == true,
      "Failed to transferFrom tokens"
    );
  }

  function ensureTransfer(IERC20 _token, address _to, uint256 _amount) internal {
    require(
      _token.transfer(_to, _amount) == true,
      "Failed to transfer tokens"
    );
  }
}
