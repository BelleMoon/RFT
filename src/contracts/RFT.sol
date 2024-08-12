// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "./IRFT.sol";

/// @title Refundable Token
/// @author Labelle Moon (hugo.card)
/// @dev A no intermediaries eletronic refund time-ensured system.

contract RFT is ERC20, IRFT {
  /*
      This is a refund. By definition, a refund is set by a struct containing
    an `issuer`, defined as the address that made the refundable transaction;
    the `amount`; and the `blockEnd`, which is the block number when the
    transaction is unrefundable.
  */

  struct Refund {
    address issuer;
    uint128 amount;
    uint128 blockEnd;
  }

  /*
      This is the minimal refund block. As defined, the `value` of it is the
    minimal value of the block limit; `lastChange` is the block number when
    the minimal refund block `value` was last changed; `desiredChangeValue` is
    the integer value that the `value` will change when a change is happening;
    `isChangeRunning` is the boolean of the minimal refund block change state.
  */

  struct MinimalRefundBlock {
    uint256 value;
    uint256 lastChange;
    uint256 desiredChangeValue;
    bool isChangeRunning;
  }

  /*
      The `_addrTransactionsRefunds` is the central storage of the refunds. It's used
    for storing refunds in the recipient of a transaction key by using an array.
      Refunds in this mapping are not ordered and can be empty.

      The minimal refund block mapping is set here. It stores the minimal refund
    block object of an address.
  */

  mapping(address => Refund[]) private _addrTransactionsRefunds;
  mapping(address => MinimalRefundBlock) private _addrMinimalRefundBlock;

  /*
      The `_addrDebtAmount` stores the amount of debt of an address. Debts are
    values that can be refund by another address. The debt amount defined in
    this mapping can be outdated, and can be changed every time a refund is
    made, a transaction happens, or `_clearDebt` method is called.
  */

  mapping(address => uint256) private _addrDebtAmount;

  /*
      Definition of the uniswap router and pair. These are needed to facilitate
    the token pair creation.
  */

  /*IUniswapV2Router02 public immutable uniswapV2Router;
  address public immutable uniswapV2Pair;*/

  constructor() ERC20("Refundable Token", "RFT") {
    uint256 _initialSupply = 10 ** 24;

    // Uniswap pair creation by using router v2.

    /*IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

    uniswapV2Router = _uniswapV2Router;
    uniswapV2Pair = _uniswapV2Pair;*/

    _mint(msg.sender, _initialSupply);
  }

  receive() external payable { }

  /**
   * @dev This method implements the ability to cancel a minimal refund block
   * change.
   */

  function cancelMinimalRefundBlockChange(
  ) external override returns (bool) {
    _cancelMinimalRefundBlockChange(_msgSender());
    return true;
  }

  /**
   * @dev This method changes the minimal refund block.
   *
   * This method should be called two times. At the first time, it acts
   * like a counter of minimal refund block `value` blocks.
   *
   * After the counter ends, and the method is called again,
   * the `desiredChangeValue` is assigned to minimal refund block `value` of
   * the address.
   *
   */

  function changeMinimalRefundBlock(
    uint256 value
  ) external override returns (bool) {
    _changeMinimalRefundBlock(_msgSender(), value);
    return true;
  }

  /**
   * @dev Implements a public burn method.
   */
  function burn(
    uint256 amount
  ) external override returns (bool) {
    _burn(_msgSender(), amount);
    return true;
  }

  /**
   * @dev Used to clear debts of an address by specifying an array containing
   * the indices of expired refunds. These will be deleted and the total amount
   * of discounted debt will be returned by the method.
   */

  function clearDebt(
    uint256[] memory debtIndices
  ) external override returns (bool) {
    address owner = _msgSender();

    uint256 discountedDebt = _clearDebt(owner, debtIndices);
    _addrDebtAmount[owner] = _addrDebtAmount[owner] - discountedDebt;

    return true;
  }

  /**
   * @dev Used to refund a transaction while it's refundable. After a refund is
   * done, it is deleted from the recipient `_addrTransactionsRefunds`.
   *
   * Requirements:
   *
   * - The `sender` and `recipient` cannot be the zero address.
   * - The `id` should correspond a refund.
   * - The `sender` should be equal to the refund's `issuer`.
   * - The `blockEnd` should be lower than the current block.
   */
  function getRefund(
    address recipient,
    uint256 id,
    uint128 refundAmount
  ) external override returns (bool) {
    _getRefund(_msgSender(), recipient, id, refundAmount);
    return true;
  }

  /**
   * @dev Returns a specific target refund from `_addrTransactionsRefunds`.
   */
  function seeRefund(
    address target,
    uint256 id
  ) external view override returns (address, uint256, uint256) {
    Refund memory targetRefund = _addrTransactionsRefunds[target][id];

    address issuer = targetRefund.issuer;
    uint256 amount = targetRefund.amount;
    uint256 blockEnd = targetRefund.blockEnd;

    return (issuer, amount, blockEnd);
  }

  /**
   * @dev Returns the length of `_addrTransactionsRefunds` of a target address.
   */
  function seeRefundSize(
    address target
  ) external view override returns (uint256) {
    return _addrTransactionsRefunds[target].length;
  }

  /**
   * @dev Returns the `_minimalRefundBlock` of a specific address.
   */
  function seeMinimalRefundBlock(
    address target
  ) external view override returns (uint256, uint256, uint256, bool) {
    uint256 value = _addrMinimalRefundBlock[target].value;
    uint256 lastChange = _addrMinimalRefundBlock[target].lastChange;
    uint256 desiredChangeValue = _addrMinimalRefundBlock[target].desiredChangeValue;

    bool isChangeRunning = _addrMinimalRefundBlock[target].isChangeRunning;

    return (value, lastChange, desiredChangeValue, isChangeRunning);
  }

  /**
   * @dev Returns the debt amount of an address. May return an incorrect debt
   * amount.
   */
  function seeAddrDebtAmount(
    address target
  ) external view override returns (uint256) {
    return _addrDebtAmount[target];
  }

  /**
   * @dev Returns refunds that are not deleted.
   *
   * The return type is an array containing the indices of `_addrTransactionsRefunds`
   * of these refunds.
   */
  function fetchRefunds(
    address target
  ) external view returns (uint256[] memory) {
    Refund[] memory targetRefunds = _addrTransactionsRefunds[target];

    uint256 outSize;
    uint256 outKey;

    for (uint256 index; index < targetRefunds.length; index++) {
      if (targetRefunds[index].blockEnd != 0) {
        outSize += 1;
      }
    }

    /*
        It's necessary to loop two times because solidity doesn't support
      dynamic arrays in memory.
    */

    uint256[] memory output = new uint256[](outSize);

    for (uint256 index; index < targetRefunds.length; index++) {
      if (targetRefunds[index].blockEnd != 0) {
        output[outKey] = index;
        outKey += 1;
      }
    }

    return output;
  }

  /**
   * @dev Moves amount from `sender` to `recipient` by using or not a refundable
   * transaction.
   *
   *  The minimal refund block checking, and the debt checking occurs in every
   * transaction.
   */
  function transfer(
    address to,
    uint256 amount,
    uint256 blockLimit,
    uint256[] memory debtsIndices
  ) public override returns (bool) {
    address owner = _msgSender();

    if (blockLimit < _addrMinimalRefundBlock[owner].value) {
      blockLimit = _addrMinimalRefundBlock[owner].value;
    }

    _debtCheck(owner, amount, debtsIndices);
    _transfer(owner, to, amount);
    _whenTransactionCompleted(owner, to, amount, blockLimit);

    return true;
  }

  function transfer(
    address to, 
    uint256 amount
  ) public virtual override returns (bool) {
    uint256[] memory emptyDebtsIndices;
    transfer(to, amount, 0, emptyDebtsIndices);

    return true;
  }

  /**
   * @dev Moves amount from `from` to `to` by using allowance mechanism. This
   * method does not accept refundable transactions.
   */
  function transferFrom(
    address from,
    address to,
    uint256 amount,
    uint256[] memory debtIndices
   ) public override returns (bool) {
       address spender = _msgSender();

       require(_addrMinimalRefundBlock[from].value == 0, "RFT: MRB is different of zero.");

       _debtCheck(from, amount, debtIndices);
       _spendAllowance(from, spender, amount);
       _transfer(from, to, amount);

       return true;
   }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public virtual override returns (bool) {
      uint256[] memory emptyDebtIndice;
      transferFrom(from, to, amount, emptyDebtIndice);

      return true;
  }

  /**
   * @dev This is just executed if a refundable transaction is made.
   *
   * A refund object is created and is pushed to the recipient
   * `_addrTransactionsRefunds`.
   *
   * The debt amount of the recipient in increased by the transaction's amount.
   */
  function _whenTransactionCompleted(
    address sender,
    address recipient,
    uint256 amount,
    uint256 blockLimit
  ) internal virtual {
    if (blockLimit > 0) {
      Refund memory recipientRefund;

      recipientRefund.issuer = sender;
      recipientRefund.amount = uint128(amount);
      recipientRefund.blockEnd = uint128(block.number + blockLimit);

      _addrTransactionsRefunds[recipient].push(recipientRefund);
      _addrDebtAmount[recipient] += amount;
    }
  }

  /**
   * @dev Checks for debts in addresses so the refund is not avoidable by
   * sending it to another address while the transaction is refundable.
   *
   *  It works by calculating the free balance of the sender, and in case the
   * amount is less or equal than it the transactions proceeds. If not, the
   * `debtIndices` can be specified containing the indices of refundable
   * transactions of the recipient that expired. These will be deleted and the
   * debt amount discounted. The free balance is calculated again with the
   * discounted debt and if the amount is less or equal than it, the transaction
   * proceeds. If not by the second time, the function reverts.
   */
  function _debtCheck(
    address sender,
    uint256 amount,
    uint256[] memory debtsIndices
  ) internal virtual {
    uint256 actualDebt = _addrDebtAmount[sender];
    uint256 actualBalance = balanceOf(sender);
    uint256 preliminarFreeBalance = actualBalance - actualDebt;

    if (amount > preliminarFreeBalance) {
      uint256 discountedDebt = _clearDebt(sender, debtsIndices);

      uint256 calculatedDebt = actualDebt - discountedDebt;
      uint256 calculatedFreeBalance = actualBalance - calculatedDebt;

      require(amount <= calculatedFreeBalance, "RFT: Not enough free balance.");
      _addrDebtAmount[sender] = calculatedDebt;
    }
  }

  function _cancelMinimalRefundBlockChange(
    address sender
  ) internal virtual {
    _addrMinimalRefundBlock[sender].isChangeRunning = false;
  }

  function _changeMinimalRefundBlock(
    address sender,
    uint256 value
  ) internal virtual {
    if (_addrMinimalRefundBlock[sender].isChangeRunning == false) {
      _addrMinimalRefundBlock[sender].isChangeRunning = true;
      _addrMinimalRefundBlock[sender].lastChange = block.number;
      _addrMinimalRefundBlock[sender].desiredChangeValue = value;
    } else {
      require(
        block.number - _addrMinimalRefundBlock[sender].lastChange >= _addrMinimalRefundBlock[sender].value,
        "RFT: The min time is not over."
      );

      _addrMinimalRefundBlock[sender].isChangeRunning = false;
      _addrMinimalRefundBlock[sender].value = _addrMinimalRefundBlock[sender].desiredChangeValue;
    }
  }

  function _clearDebt(
    address sender,
    uint256[] memory debtIndices
  ) internal virtual returns (uint256) {
    uint256 discountedDebt;
    uint256 debtIndicesLength = debtIndices.length;

    require(debtIndicesLength > 0, "RFT: Debt indices not specified.");

    for (uint256 index; index < debtIndicesLength; index++) {
      uint256 debtKey = debtIndices[index];
      uint256 debtBlockEnd = _addrTransactionsRefunds[sender][debtKey].blockEnd;

      if (debtBlockEnd != 0) {
        if (block.number >= debtBlockEnd) {
          discountedDebt += _addrTransactionsRefunds[sender][debtKey].amount;
          delete _addrTransactionsRefunds[sender][debtKey];
        }
      }
    }

    return discountedDebt;
  }

  function _getRefund(
    address sender,
    address recipient,
    uint256 id,
    uint128 refundAmount
  ) internal virtual {
    require(sender != address(0), "RFT: refund from zero address");
    require(recipient != address(0), "RFT: refund to zero address");
    require(_addrTransactionsRefunds[recipient][id].blockEnd != 0, "RFT: There is no refund");

    address checkAddress = _addrTransactionsRefunds[recipient][id].issuer;
    require(checkAddress == sender, "RFT: This refund is not valid");

    uint256 blockLimitStored = _addrTransactionsRefunds[recipient][id].blockEnd;
    require(block.number < blockLimitStored, "RFT: Refunding is over");

    uint256 transactionAmount = _addrTransactionsRefunds[recipient][id].amount;

    require(refundAmount <= transactionAmount, "The refund amount is too high.");
    require(refundAmount != 0, "The refund amount is zero.");

    if (refundAmount == transactionAmount) {
      // That's the case where all the refund will be removed.

      _transfer(recipient, sender, transactionAmount);
      _addrDebtAmount[recipient] -= transactionAmount;

      delete _addrTransactionsRefunds[recipient][id];
    } else {
      // That's the case where the refund will be partially removed.

      _transfer(recipient, sender, refundAmount);
      _addrDebtAmount[recipient] -= refundAmount;
      
      _addrTransactionsRefunds[recipient][id].amount -= refundAmount;
    }
  }
}
