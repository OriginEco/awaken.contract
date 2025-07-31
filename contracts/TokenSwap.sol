// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "hardhat/console.sol";

contract StableTokenSwap is
  Initializable,
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable
{
  using SafeERC20Upgradeable for IERC20Upgradeable;

  IERC20Upgradeable public tokenA;
  IERC20Upgradeable public tokenB;

  bool public enableA2B;
  bool public enableB2A;

  event Withdraw(address indexed token, address indexed to, uint256 amount);
  event Exchanged(
    address indexed user,
    address indexed fromToken,
    address indexed toToken,
    uint256 amount
  );
  event SetEnableA2B(bool enabled);
    event SetEnableB2A(bool enabled);
    event OwnershipWithdraw(address indexed token, uint256 amount);

  //Add this line to protect the upgradable contract.
  constructor()  initializer  {}

  function initialize(address _tokenA, address _tokenB) public initializer {
    require(
      _tokenA != address(0) && _tokenB != address(0),
      "Invalid token address"
    );
    require(_tokenA != _tokenB, "Token addresses must differ");

    __Context_init(); 
    __Ownable_init(); 
    __ReentrancyGuard_init(); 

    tokenA = IERC20Upgradeable(_tokenA);
    tokenB = IERC20Upgradeable(_tokenB);

    enableA2B = true;
    enableB2A = true;
  }

  function exchange(address fromToken, uint256 amount) external nonReentrant {
    require(amount > 0, "Amount must be greater than zero");
    console.log(amount);
    require(
      fromToken == address(tokenA) || fromToken == address(tokenB),
      "Unsupported token"
    );
    console.log("token is ok");

    bool isA2B = fromToken == address(tokenA);
    bool isB2A = fromToken == address(tokenB);

    require(
      (isA2B && enableA2B) || (isB2A && enableB2A),
      "Exchange direction disabled"
    );

    console.log("enable is ok");

    IERC20Upgradeable from = isA2B ? tokenA : tokenB;
    IERC20Upgradeable to = isA2B ? tokenB : tokenA;

    // 檢查合約是否有足夠目標代幣進行兌換
    require(
      to.balanceOf(address(this)) >= amount,
      "Insufficient liquidity for swap"
    );

    console.log("balance is ok");

    from.safeTransferFrom(msg.sender, address(this), amount);
    to.safeTransfer(msg.sender, amount);

    emit Exchanged(msg.sender, address(from), address(to), amount);
  }

  function setEnableA2B(bool enabled) external onlyOwner {
    enableA2B = enabled;
    emit SetEnableA2B(enabled);
  }

  function setEnableB2A(bool enabled) external onlyOwner {
    enableB2A = enabled;
     emit SetEnableB2A(enabled);
  }

  function getReserves()
    external
    view
    returns (uint256 reserveA, uint256 reserveB)
  {
    reserveA = tokenA.balanceOf(address(this));
    reserveB = tokenB.balanceOf(address(this));
  }

  function withdraw(address token, uint256 amount) external onlyOwner {
    IERC20Upgradeable(token).safeTransfer(msg.sender, amount);
    emit OwnershipWithdraw(token, amount);
    emit Withdraw(token, msg.sender, amount);
  }
}
