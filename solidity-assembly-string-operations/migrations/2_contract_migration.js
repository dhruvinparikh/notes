const StringFunctions = artifacts.require("StringFunctions");
const StringFunctionsAssembly = artifacts.require("StringFunctionsAssembly");

module.exports = function(deployer) {
  deployer.deploy(StringFunctions);
  deployer.deploy(StringFunctionsAssembly);
};
