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
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../Converter.sol";
import "../ContinuousToken.sol";
import "../EthToFixedSupplyExchange.sol";


contract EthToFixedSupplyDistributionFactory is Ownable {

  event SetFee(uint256 _fee);
  event SetFeeBeneficiary(address indexed _fee);
  event Build(
    address indexed fixedToken,
    address indexed weth,
    address continuousToken,
    address converter,
    address ethToFixedSupplyExchange
  );

  uint256 public fee;
  address payable public feeBeneficiary;
  address public bancorFormula;

  constructor(
    uint256 _fee,
    address payable _feeBeneficiary,
    address _bancorFormula
  )
    public
    Ownable()
  {
    fee = _fee;
    feeBeneficiary = _feeBeneficiary;
    bancorFormula = _bancorFormula;
  }

  // OWNER INTERFACE

  function setBancorFormula(address _bancorFormula) external onlyOwner {
    bancorFormula = _bancorFormula;
  }

  function setFee(uint256 _fee) external onlyOwner {
    fee = _fee;

    emit SetFee(_fee);
  }

  function setFeeBeneficiary(address payable _feeBeneficiary) external onlyOwner {
    feeBeneficiary = _feeBeneficiary;

    emit SetFeeBeneficiary(_feeBeneficiary);
  }

  // USER INTERFACE

  function build(
    address _weth,
    address _fixedToken,
    uint32 _continuousTokenReserveRatio,
    uint32 _continuousTokenMaxFee,
    uint32 _continuousTokenFee,
    address _continuousTokenFeeBeneficiary,
    address _initialMintBeneficiary,
    uint256 _initialMintAmount
  )
    external
    payable
  {
    _acceptPayment();

    ContinuousToken continuousToken = new ContinuousToken(
      _continuousTokenReserveRatio,
      _continuousTokenMaxFee,
      _continuousTokenFee,
      _continuousTokenFeeBeneficiary,
      _weth,
      bancorFormula,
      _initialMintBeneficiary,
      _initialMintAmount
    );

    continuousToken.setGasPriceModifier(msg.sender);
    continuousToken.transferOwnership(msg.sender);

    Converter converter = new Converter(_fixedToken, address(continuousToken));
    EthToFixedSupplyExchange ethToFixedSupplyExchange = new EthToFixedSupplyExchange(
      address(continuousToken),
      _fixedToken,
      _weth,
      address(converter)
    );

    emit Build(
      _fixedToken,
      _weth,
      address(continuousToken),
      address(converter),
      address(ethToFixedSupplyExchange)
    );
  }

  // INTERNAL

  function _acceptPayment() internal {
    require(msg.value == fee, "Invalid fee");

    feeBeneficiary.transfer(msg.value);
  }
}
