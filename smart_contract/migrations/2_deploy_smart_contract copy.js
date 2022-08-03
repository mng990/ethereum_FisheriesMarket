const ItemContract = artifacts.require("ItemContract");
const SupplyContract = artifacts.require("SupplyContract");
const AuctionContract = artifacts.require("AuctionContract");
const rwSupplyData = artifacts.require("rwSupplyData");

module.exports = function (deployer) {
  deployer.deploy(ItemContract);
  deployer.deploy(SupplyContract);
  deployer.deploy(AuctionContract);
  deployer.deploy(rwSupplyData);
};