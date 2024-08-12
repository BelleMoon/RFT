// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRFT {
  /* Transfering methods declaration. */
  function transfer(
    address to,
    uint256 amount,
    uint256 blockLimit,
    uint256[] memory debtsIndices
  ) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 amount,
    uint256[] memory debtIndices
   ) external returns (bool);

  /* Refund method declaration. */
  function getRefund(address recipient, uint256 id, uint128 refundAmount) external returns (bool);

  /* Implements a public burn method. */
  function burn(uint256 amount) external returns (bool);

  /* Debt controlling method. */
  function clearDebt(
    uint256[] memory debtIndices
  ) external returns (bool);

  /* Minimal refund block control methods. */
  function changeMinimalRefundBlock(
    uint256 value
  ) external returns (bool);

  function cancelMinimalRefundBlockChange() external returns (bool);

  /* Methods to check refunds and the minimal refund block values. */
  function seeRefund(
    address target,
    uint256 id
  ) external view returns (address, uint256, uint256);

  function seeRefundSize(
    address target
  ) external view returns (uint256);

  function seeMinimalRefundBlock(
    address target
  ) external view returns (uint256, uint256, uint256, bool);

  /* Method to check the debt amount of an address. */
  function seeAddrDebtAmount(
    address target
  ) external view returns (uint256);

  /* Auxiliar method to search for refunds that weren't deleted. */
  function fetchRefunds(
    address target
  ) external view returns (uint256[] memory);
}
