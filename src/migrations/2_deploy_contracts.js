var RefundableToken = artifacts.require("RFT");

module.exports = function(deployer) {
  deployer.deploy(RefundableToken);
};
