let instance = await RFT.deployed();
let accounts = await web3.eth.getAccounts();

// Realizes a normal transference.
await instance.transfer(accounts[1], 1000, 5000, []);
await instance.transfer(accounts[1], 1000, 0, []);

await instance.transfer(accounts[2], 1000, 5, [], {"from": accounts[1]});

await instance.changeMinimalRefundBlock(30);
await instance.clearDebt([0]);

// Gas testing with uint256

await instance.transfer(accounts[1], 1000, 5000, []); // => gasUsed: 168982
await instance.transfer(accounts[1], 1000, 5000, []); // => gasUsed: 117682

// After uint128()

await instance.transfer(accounts[1], 1000, 5000, []); // => gasUsed: 147026
await instance.transfer(accounts[1], 1000, 5000, []); // => gasUsed: 95726

await instance.getRefund(accounts[1], 0, 500)