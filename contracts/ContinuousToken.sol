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
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IBancorFormula.sol";
import "./interfaces/IContinuousToken.sol";


contract ContinuousToken is IContinuousToken, ERC20, Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  uint32 private constant RATIO_RESOLUTION = 1000000;
  uint32 private constant CONVERSION_FEE_RESOLUTION = 1000000;

  uint32 public reserveRatio;
  uint32 public maxConversionFee;
  uint32 public conversionFee;
  address public feeBeneficiary;

  uint256 public gasPrice;
  address public gasPriceModifier;

  IERC20 public reserveToken;
  IBancorFormula public bancorFormula;

  modifier onlyValidGasPrice() {
    require(tx.gasprice <= gasPrice, "Invalid gasprice");

    _;
  }

  constructor (
    uint32 _reserveRatio,
    uint32 _maxConversionFee,
    uint32 _conversionFee,
    address _feeBeneficiary,
    address _reserveToken,
    address _bancorFormula,
    address _initialMintBeneficiary,
    uint256 _initialMintAmount
  ) public {
    require(_reserveRatio > 0 && _reserveRatio <= RATIO_RESOLUTION, "Invalid reserve ratio");
    // TODO: support 0
    require(_conversionFee > 0 && _conversionFee <= CONVERSION_FEE_RESOLUTION, "Invalid conversion fee");
    require(_initialMintAmount > 0, "Invalid initial mint amount");

    reserveRatio = _reserveRatio;
    maxConversionFee = _maxConversionFee;
    conversionFee = _conversionFee;
    feeBeneficiary = _feeBeneficiary;
    reserveToken = IERC20(_reserveToken);
    bancorFormula = IBancorFormula(_bancorFormula);

    _mint(_initialMintBeneficiary, _initialMintAmount);
  }

  // OWNER INTERFACE

  function setConversionFee(uint32 _conversionFee) external onlyOwner {
    require(_conversionFee <= maxConversionFee, "Expect _conversionFee <= maxConversionFee");

    conversionFee = _conversionFee;

    emit SetConversionFee(_conversionFee);
  }

  function setFeeBeneficiary(address _feeBeneficiary) external onlyOwner {
    feeBeneficiary = _feeBeneficiary;

    emit SetFeeBeneficiary(_feeBeneficiary);
  }

  function setGasPrice(uint256 _gasPrice) external {
    require(msg.sender == gasPriceModifier, "Only gasPriceModifier allowed");

    gasPrice = _gasPrice;

    emit SetGasLimit(_gasPrice);
  }

  function setGasPriceModifier(address _gasPriceModifier) external onlyOwner {
    gasPriceModifier = _gasPriceModifier;

    emit SetGasPriceModifier(_gasPriceModifier);
  }

  // USER INTERFACE

  /**
   * @dev msg.sender deposits `reserve` tokens to the contract and receives `continuous` tokens in exchange
   */
  function buy(
    uint256 _depositAmount,
    uint256 _minReturn
  )
    external
    onlyValidGasPrice
    returns (uint256 amount, uint256 feeAmount)
  {
    (amount, feeAmount) = getPurchaseReturn(_depositAmount);
    require(amount != 0 && amount >= _minReturn, "Invalid getPurchaseReturn amount");

    _mint(msg.sender, amount);
    _mint(feeBeneficiary, feeAmount);

    reserveToken.transferFrom(msg.sender, address(this), _depositAmount);

    emit Buy(msg.sender, _depositAmount, amount, feeAmount);
    emit PriceUpdate(totalSupply(), getReserveBalance());
  }

  /**
   * @dev msg.sender sells `continuous` tokens and receives `reserve` tokens in exchange
   */
  function sell(
    uint256 _sellAmount,
    uint256 _minReturn
  )
    external
    onlyValidGasPrice
    returns (uint256 amount, uint256 feeAmount)
  {
    require(_sellAmount <= balanceOf(msg.sender), "Not enough funds to sell");

    (amount, feeAmount) = getSaleReturn(_sellAmount);
    require(amount != 0 && amount >= _minReturn, "Invalid getSaleReturn amount");

    // ensure that the trade will only deplete the reserve balance if the total supply is depleted as well
    uint256 tokenSupply = totalSupply();
    uint256 reserveBalance = getReserveBalance();
    assert(amount < reserveBalance || (amount == reserveBalance && _sellAmount == tokenSupply));

    _burn(msg.sender, _sellAmount);

    reserveToken.transfer(msg.sender, amount);
    reserveToken.transfer(feeBeneficiary, feeAmount);

    emit Sell(msg.sender, _sellAmount, amount, feeAmount);
    emit PriceUpdate(totalSupply(), getReserveBalance());
  }

  // VIEW

  function getPurchaseReturn(uint256 _depositAmount) public view returns (uint256, uint256) {
    uint256 tokenSupply = totalSupply();
    uint256 reserveBalance = getReserveBalance();
    uint256 amount = bancorFormula.calculatePurchaseReturn(tokenSupply, reserveBalance, reserveRatio, _depositAmount);
    uint256 finalAmount = getFinalAmount(amount, 1);

    // return the amount minus the conversion fee and the conversion fee
    // return (finalAmount, amount - finalAmount);
    return (finalAmount, amount.sub(finalAmount));
  }

  function getSaleReturn(uint256 _sellAmount) public view returns (uint256, uint256) {
    uint256 tokenSupply = totalSupply();
    uint256 reserveBalance = getReserveBalance();
    uint256 amount = bancorFormula.calculateSaleReturn(tokenSupply, reserveBalance, reserveRatio, _sellAmount);
    uint256 finalAmount = getFinalAmount(amount, 1);

    // return the amount minus the conversion fee and the conversion fee
    // return (finalAmount, amount - finalAmount);
    return (finalAmount, amount.sub(finalAmount));
  }

  /**
   * @dev Given a return amount, returns the amount minus the conversion fee
   *
   * @param _amount      return amount
   * @param _magnitude   1 for standard conversion, 2 for cross reserve conversion
   *
   * @return return amount minus conversion fee
   */
  function getFinalAmount(uint256 _amount, uint8 _magnitude) public view returns (uint256) {
    return _amount.mul((CONVERSION_FEE_RESOLUTION - conversionFee) ** _magnitude).div(CONVERSION_FEE_RESOLUTION ** _magnitude);
  }

  /**
   * @dev Returns the reserve's balance
   *
   * @return reserve balance
   */
  function getReserveBalance() public view returns (uint256) {
    return reserveToken.balanceOf(address(this));
  }
}
