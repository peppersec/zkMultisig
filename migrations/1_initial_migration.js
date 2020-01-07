const zkMultisig = artifacts.require("zkMultisig");

module.exports = function(deployer) {
  deployer.deploy(zkMultisig);
};
