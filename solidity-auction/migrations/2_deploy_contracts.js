var AuctionFactory = artifacts.require("./AuctionFactory.sol");
// var Auction = artifacts.require("./Auction.sol");

module.exports = function(deployer,network,accounts) {
  // deployer.deploy(ConvertLib);
  // deployer.autolink();
  // deployer.deploy(MetaCoin);
  deployer.deploy(AuctionFactory);
  // deployer.deploy(Auction);
};
