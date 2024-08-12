var RefundableToken = artifacts.require("RFT");

let instance;
let total_supply;

contract("Refundable Token", async accounts => {

  beforeEach(async () => {
    instance = await RefundableToken.new();
    total_supply = await instance.totalSupply();
  });

  it("should mint the right token amount to accounts[0]", async function() {

    var account_amount = await instance.balanceOf(accounts[0]);

    assert.equal(
      account_amount.toString(),
      total_supply.toString(),
      "Initial supply was not correctly minted."
    );
  });

  it("should make a sucessful transaction", async function() {
    // Realizes the transference.
    var amount = 100;
    var block_limit = 20;
    await instance.transfer(accounts[1], amount, block_limit, []);

    // Obtain the block number of the transaction.
    var block_transaction = await web3.eth.getBlock("latest");
    var block_transaction_number = block_transaction.number;

    // Check if the sender balance match.
    var sender_balance = await instance.balanceOf(accounts[0]);
    var sender_expected_balance = total_supply.sub(web3.utils.toBN(amount));

    assert.equal(
      sender_balance.toString(),
      sender_expected_balance.toString(),
      "Sender balance doesn't match."
    );

    // Check if recipient balance match
    var recipient_balance = await instance.balanceOf(accounts[1]);
    assert.equal(recipient_balance.toString(), amount.toString(), "Recipient balance doesn't match.");

    // Check if the refund is correctly set.
    var refund_arr = await instance.seeRefund(accounts[1], 0);

    var refund = [
      refund_arr[0].toString(),
      refund_arr[1].toNumber(),
      refund_arr[2].toNumber()
    ];
    var refund_expected = [
      accounts[0],
      amount,
      block_transaction_number + block_limit
    ];

    assert.equal(refund[0], refund_expected[0], "Refund issuer address doesn't match.");
    assert.equal(refund[1], refund_expected[1], "Refund amount is not correct.");
    assert.equal(refund[2], refund_expected[2], "Refund block limit is not correct.");

    // Check if refund length is correct.
    var refund_size_1 = (await instance.seeRefundSize(accounts[0])).toString();
    var refund_size_2 = (await instance.seeRefundSize(accounts[1])).toString();
    var refund_size_3 = (await instance.seeRefundSize(accounts[2])).toString();

    assert.equal(refund_size_1, "0", "Refund size of the first account is incorrect.");
    assert.equal(refund_size_2, "1", "Refund size of the second account is incorrect.");
    assert.equal(refund_size_3, "0", "Refund size of the third account is incorrect.");

    // Check if fetch refunds is correctly working.
    var fetch_refund_return = (await instance.fetchRefunds(accounts[1])).toString();
    assert.equal(fetch_refund_return, "0", "The fetch refund method is not correctly executed.")
  });

  it("should make a sucessful refund", async function() {
    let sender_start_balance = (await instance.balanceOf(accounts[0])).toString();
    let recipient_start_balance = (await instance.balanceOf(accounts[1])).toString();

    let amount = 1000;
    let block_limit = 30;

    await instance.transfer(accounts[1], amount, block_limit, []);
    let recipientStartDebtAmount = (await instance.seeAddrDebtAmount(accounts[1])).toString();

    assert.equal(
      recipientStartDebtAmount,
      amount.toString(),
      "The recipient debt amount is incorrect BEFORE refund"
    );

    await instance.getRefund(accounts[1], 0, amount);

    let sender_end_balance = (await instance.balanceOf(accounts[0])).toString();
    let recipient_end_balance = (await instance.balanceOf(accounts[1])).toString();

    assert.equal(
      sender_end_balance,
      sender_start_balance,
      "The amount from sender was not correctly refunded. Balances dismatch."
    );

    assert.equal(
      recipient_end_balance,
      recipient_start_balance,
      "The amount from recipient was not correctly refunded. Balances dismatch."
    );

    let fetchedRefunds = (await instance.fetchRefunds(accounts[1])).toString();

    assert.equal(
      fetchedRefunds,
      "",
      "The refund was not correctly marked as unrefundable or fetchRefunds is acting wrongly."
    );

    let recipientEndDebtAmount = (await instance.seeAddrDebtAmount(accounts[1])).toString();

    assert.equal(
      recipientEndDebtAmount,
      "0",
      "The recipient debt amount is incorrect AFTER refund"
    );
  });

  it("should handle multiple transferences correctly", async function() {
    // Realizes the transference.
    var amount = 100;
    var block_limit = 20;

    await instance.transfer(accounts[1], amount, 1, []);
    await instance.transfer(accounts[1], amount, block_limit, []);

    // Balance checking
    let sender_balance = await instance.balanceOf(accounts[0]);
    let recipient_balance = await instance.balanceOf(accounts[1]);

    let expected_sender_balance = total_supply.sub(web3.utils.toBN(amount * 2));
    let expected_recipient_balance = web3.utils.toBN(amount * 2);

    assert.equal(
      sender_balance.toString(),
      expected_sender_balance.toString(),
      "The sender balance is incorrectly set. Balances dismatch."
    );

    assert.equal(
      recipient_balance.toString(),
      expected_recipient_balance.toString(),
      "The recipient balance is incorrectly set. Balances dismatch."
    );

    // Debt checking
    let recipientDebtAmount = (await instance.seeAddrDebtAmount(accounts[1])).toString();

    assert.equal(
      recipientDebtAmount,
      (amount * 2).toString(),
      "Recipient debt checking mismatch."
    )

    // Debt free balance testing
    try {
      await instance.transfer(accounts[2], 100, 5, [], {"from": accounts[1]});
    } catch (error) {
      assert.equal(
        error.reason,
        "RFT: Debt indices not specified.",
        "Debt indices error not thrown."
      )
    }

    // Debt indices specifying test.
    await instance.transfer(accounts[2], 100, 5, [0], {"from": accounts[1]});

  });

  it("should set minimal refund block correctly", async function() {

  });

  it("should check for debts correctly", async function() {

  });

  it("should change the minimal refund block correctly", async function() {
    /*
      Initial MRB checking.

      -> Initial value should be zero.
      -> Last change should be zero
      -> desired value change sould be zero.
      -> isChangeRunning should be zero.
    */
    /* Base test */

    await instance.changeMinimalRefundBlock(0)
  });
});
