# Refundable Token (RFT)

## A Decentralized Time-Ensured Refund System

### Overview
The Refundable Token (RFT) is a novel ERC20-compatible smart contract implementation that introduces structured refundability into blockchain transactions. By leveraging minimal refund block constraints and debt-checking mechanisms, the RFT framework ensures that transactions can be reversed within a predefined time window while maintaining security and decentralization.

## Motivation

One of the core limitations of traditional cryptocurrencies is the irreversibility of transactions. This poses risks in cases of accidental transfers, fraud, or time-sensitive payments where delays can lead to financial losses. The RFT protocol addresses this issue by enabling time-constrained, issuer-approved refunds without relying on intermediaries.

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

1. **Initiation:** Starts a countdown equal to the current MRB.
2. **Countdown Period:** Ensures a gradual transition to prevent exploitation.
3. **Completion:** The MRB is updated after the countdown expires.
4. **Cancellation:** Users can abort the MRB change using `cancelMinimalRefundBlockChange()` to prevent unintended modifications.

### Debt Checking Mechanism

To counteract the "Send Before Refund" attack, RFT enforces debt checking:

- Calculates an address’s total refundable debt.
- Computes the free balance (total balance - refundable amounts).
- Ensures transactions do not exceed the free balance.
- Allows users to specify debt indices to optimize gas costs.

### Refund System

Refunds are managed through a structured on-chain storage system:

- **Storage Structure:** Refundable transactions are stored in `_addrTransactionsRefunds` mapping.
- **Refund Retrieval:** The `getRefund(recipient, id)` function allows transaction issuers to reclaim refundable amounts.
- **Security Checks:** Ensures only original issuers can process refunds and that requests are within the valid block range.

## Setup & Deployment

### Prerequisites
To build and test the RFT contract, the following dependencies are required:

- [Node.js](https://nodejs.org/)
- [Truffle](https://trufflesuite.com/)
- [Mocha](https://mochajs.org/)
- [Solidity](https://soliditylang.org/)

### Installation
```sh
npm install -g truffle
```

### Running Tests
Automated tests are implemented using Mocha and the Truffle framework. To execute the test suite:
```sh
npm test
```
Test cases validate core functionalities, including:
- Transaction refundability
- Minimal Refund Block modifications
- Debt checking enforcement
- Secure refund processing

## Results & Performance

The RFT contract was tested in a Ganache environment, confirming:
- **Successful Refund Execution:** Transactions revert as expected within the defined block limit.
- **Gas Efficiency:** Key operations maintain O(1) complexity, ensuring minimal computational overhead.
- **Robust Security:** Debt checking prevents unauthorized fund transfers.

## Authors

- **Hugo Cardoso Ferreira de Araújo** - [LabelleMoon](https://github.com/BelleMoon) - [hugo.card@usp.br](mailto:hugo.card@usp.br)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

For further technical insights, refer to "Refundable_Token.pdf" included in this repository.

---
This README provides an in-depth overview of the RFT protocol’s technical implementation, security considerations, and testing framework, ensuring clear documentation for developers and researchers interested in refundable blockchain transactions.

