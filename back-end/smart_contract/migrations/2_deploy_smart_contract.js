const AuctionContract = artifacts.require("AuctionContract");
const ItemContract = artifacts.require("ItemContract");
const SupplyContract = artifacts.require("SupplyContract"); // (구) rwSupplyData
const dir = "QmX41zqMe2anHQwpqFbiZ9pT6vhDH9yar7QnnRNWW54dWh/testItem";
const dirAuc = "QmX41zqMe2anHQwpqFbiZ9pT6vhDH9yar7QnnRNWW54dWh/testAuc"

module.exports = async function (deployer) {
  await deployer.deploy(ItemContract,dir);
  await deployer.deploy(SupplyContract, ItemContract.address);
  //console.log("SupplyManaging", SupplyManagingContract.address);

  //console.log(deployer.deployed.address)

  //console.log("OwnerData", OwnerDataContract.address);

  
  await deployer.deploy(AuctionContract, ItemContract.address, SupplyContract.address, dirAuc);

  var itemSol = await ItemContract.deployed();

  var aucSol = await AuctionContract.deployed();
  await itemSol.setGovernance(AuctionContract.address); 
  await aucSol.setGovernance();
  //console.log(await aucSol.getGovernance());
};