// SPDX-License-Identifier: MIT


pragma solidity >=0.5.16;

import "./Item.sol";

contract SupplyContract {

    ItemContract itemToken;

    constructor(address _itemToken)
    {
        itemToken = ItemContract(_itemToken);
    }

    enum DeliveryStatus{
        Empty,
        Prepare,
        Delivery
    }

    struct SupplyData{
        uint256[3] deliveryTimeStamp;
        string [] envInformation;
        address producer;
        DeliveryStatus deliveryStatus;
    }

    mapping(uint256 => SupplyData) public supplyData; // auctionId -> supplyData

    modifier inState(uint256 _auctionId, DeliveryStatus _deliveryStatus) {
        require(supplyData[_auctionId].deliveryStatus == _deliveryStatus);
        _;
    }

    function updateDeliveryStatus(uint256 _auctionId, DeliveryStatus _deliveryStatus) internal {
        supplyData[_auctionId].deliveryStatus = _deliveryStatus;
        supplyData[_auctionId].deliveryTimeStamp[uint(_deliveryStatus)] = block.timestamp;
    }

    function deliveryStartByAuctionId(uint256 _auctionId) public inState(_auctionId, DeliveryStatus.Prepare){
        updateDeliveryStatus(_auctionId, DeliveryStatus.Delivery);
    }

    function deliveryEndByAuctionId(uint256 _auctionId) public inState(_auctionId, DeliveryStatus.Delivery){
        updateDeliveryStatus(_auctionId, DeliveryStatus.Empty);
    }

    function deliveryPrepareByAuctionId(uint256 _auctionId) public inState(_auctionId, DeliveryStatus.Empty){
        updateDeliveryStatus(_auctionId, DeliveryStatus.Prepare);
    }

    function getDeliveryStatusByAuctionId(uint256 _auctionId) public view returns(DeliveryStatus){
        return supplyData[_auctionId].deliveryStatus;
    }

    function getDeliveryTimeStampByAcutionId(uint256 _auctionId) public view returns(uint256[3] memory){
        return supplyData[_auctionId].deliveryTimeStamp;
    }

    // 배송 온습도 정보
    function pushEnvInformationByAuctionId(uint256 _auctionId, string memory _envInfo) public{
        supplyData[_auctionId].envInformation.push(_envInfo);
    } // 정보 추가

    function getEnvInformationByAuctionId(uint256 _auctionId) public view returns(string[] memory){
        return supplyData[_auctionId].envInformation;
    } // 정보 조회

    function inDelivery(uint256 _auctionId) public view returns(bool){
        return (supplyData[_auctionId].deliveryStatus != DeliveryStatus.Empty);
    }
}