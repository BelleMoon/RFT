# Refundable Token (RFT)

## A Decentralized Time-Ensured Refund System

### Overview
The Refundable Token (RFT) is an ERC20-compatible smart contract implementation that integrates structured refundability into blockchain transactions. This README provides an in-depth technical explanation, including smart contract functionality, implementation, and security mechanisms, with accompanying code demonstrations.

## Motivation

### **Problem Statement**
One of the fundamental issues in blockchain-based financial transactions is **irreversibility**. Once a transaction is added to the blockchain, it cannot be undone, which leads to various complications such as:
- **Accidental Transfers**: Users frequently send tokens to incorrect addresses, with no way to recover them.
- **Fraud and Theft**: If a private key is compromised, attackers can permanently steal funds.
- **Time-Sensitive Payments**: In traditional finance, scheduled payments ensure that deadlines are met. Blockchain transactions, however, are susceptible to delays due to network congestion, which can lead to penalties for missed payments.

### **Solution: Refundable Transactions with Time Constraints**
The RFT protocol introduces a refund mechanism where transactions remain **reversible for a predefined time window**. This is achieved through the concept of **Minimal Refund Block (MRB)**, which enforces a structured refundability period without compromising decentr# Refundable Token (RFT)

![Use Case Diagram](Use%20Case%20Diagram.png)

## Key Features

- **Time-Based Refundability:** Transactions remain reversible until a predefined minimal refund block is reached.
- **Debt Checking Mechanism:** Prevents the "Send Before Refund" attack by ensuring that funds eligible for refunds cannot be prematurely transferred.
- **Customizable Minimal Refund Block (MRB):** Users can adjust the refundability period for their transactions, allowing for both flexible and irreversible transactions.
- **Constant-Time (O(1)) Operations:** Efficient refund tracking and debt management using Solidity’s mapping and fixed-size array structures.
- **Secure and Trustless:** Transactions and refunds are managed through smart contracts, eliminating the need for third-party intermediaries.

## Architecture & Implementation

The RFT smart contract is implemented in Solidity and deployed on the Ethereum Virtual Machine (EVM) as an ERC20 token. The refund mechanism is enforced through the following core components:

### Transaction Structure

Each transaction in the RFT system includes:

- **Recipient:** Destination address
- **Amount:** Value being transferred
- **Block Limit:** Defines the period in which the transaction remains refundable
- **Debt Indices:** Used for verifying outstanding obligations

### Core Processes

1. **Minimal Refund Block Checking:** Ensures that each transaction adheres to the minimum refundability period.
2. **Debt Checking:** Prevents the use of refundable funds in new transactions.
3. **Balance Adjustment:** Updates sender and recipient balances accordingly.
4. **Storage Management:** Records transaction details for future reference.

### Minimal Refund Block Change Process

Users can modify the refundability period using the `changeMinimalRefundBlock(value)` function, which follows a structured time-dependent update process:
alization.

Key aspects of the solution include:
- **Fixed Refund Periods**: Transactions are reversible only until a certain block number is reached.
- **Debt Checking Mechanism**: Prevents refund exploitation by ensuring that refundable funds cannot be prematurely spent.
- **Minimal Refund Block Adjustments**: Users can configure their refundability period to fit their needs.
- **Efficiency & Security**: The system is optimized for O(1) time complexity, ensuring gas efficiency while maintaining high security standards.

## Key Features

- **Time-Based Refundability:** Transactions remain reversible until a predefined **minimal refund block** is reached.
- **Debt Checking Mechanism:** Prevents the "Send Before Refund" attack by ensuring that refundable funds cannot be prematurely transferred.
- **Customizable MRB:** Users can modify the refundability period for their transactions.
- **Efficient Gas Usage:** Constant-time (O(1)) operations using Solidity’s mapping and fixed-size array structures.
- **Secure and Trustless:** Transactions and refunds are governed by smart contracts, eliminating third-party dependence.

## Architecture & Implementation

The RFT smart contract is written in Solidity and deployed on the Ethereum Virtual Machine (EVM). The refund mechanism is enforced through structured smart contract logic, ensuring secure, trackable, and efficient refunds.

### **Transaction Structure**

Each transaction follows this structured process:

- **Recipient:** Destination address
- **Amount:** Value being transferred
- **Block Limit:** Defines the refundability period
- **Debt Indices:** Used for verifying outstanding obligations

### **Smart Contract Code Demonstration**

#### **Defining the Refund Struct**
```solidity
struct Refund {
    address issuer;
    uint128 amount;
    uint128 blockEnd;
}
```
Each refundable transaction is stored in this struct, where `issuer` is the sender, `amount` is the refund-eligible value, and `blockEnd` defines the expiration block number.

#### **Minimal Refund Block (MRB) Configuration**
```solidity
struct MinimalRefundBlock {
    uint256 value;
    uint256 lastChange;
    uint256 desiredChangeValue;
    bool isChangeRunning;
}
```
The **Minimal Refund Block** (MRB) ensures that refunds cannot be processed indefinitely. Users can modify this setting with a time delay for security.

### **Core Processes**

#### **Transaction Execution & Refund Handling**
```solidity
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
```
This function ensures that:
1. The **Minimal Refund Block** is respected.
2. Debt checking occurs before allowing transfers.
3. Refundable transactions are correctly recorded.

#### **Debt Checking Mechanism**
```solidity
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
```
This prevents users from transferring funds that are still refundable, ensuring transaction integrity.

#### **Refund Execution**
```solidity
function getRefund(
    address recipient,
    uint256 id,
    uint128 refundAmount
) external override returns (bool) {
    _getRefund(_msgSender(), recipient, id, refundAmount);
    return true;
}
```
This function allows users to request refunds within the valid block limit, ensuring that only the original sender can reclaim funds.

## Authors

- **Hugo Cardoso Ferreira de Araújo** - [LabelleMoon](https://github.com/BelleMoon) - [hugo.card@usp.br](mailto:hugo.card@usp.br)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

For further technical insights, refer to "Refundable_Token.pdf" included in this repository.

---
This README provides a detailed technical guide for developers, covering smart contract structure, implementation, and security measures for the Refundable Token (RFT).

