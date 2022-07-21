// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "./Item.sol";
import "./method.sol";



contract SupplyContract{

    ItemContract IC;
    MethodContract MC = new MethodContract();

    struct Supply{
        mapping(address => address) addrTracing;   // 경로 추적 
        mapping(address => string ) addrToShipping;  // 유저별 주소
        mapping(address => uint256 ) addrToStock;    // 유저별 소유량
        mapping(address => uint256 ) addrToOwnerIdx; // 유저별 index
        mapping(address => bool    ) isShipping;
    }

    mapping(address => bool     ) public producerCheck;
    mapping(address => uint256[]) public itemOwned;
    mapping(uint256 => Supply   ) supplyDataByItem;

    function deleveryCompleted(uint256 _itemId, address payable _bidder) public returns(bool){
        supplyDataByItem[_itemId].isShipping[_bidder] = false;
        emit DontWorryBeHappy(_itemId, _bidder);
        return true;
    }

    function setSupplyAddrToStock(uint256 _itemId, address payable _sender, uint256 _sales) public{
        Supply storage supplyData = supplyDataByItem[_itemId];
        supplyData.addrToStock[_sender] += _sales;
    }

    function setSupplyAddrToShippingAddr(uint256 _itemId, address payable _sender, string memory _shipping) public{
        Supply storage supplyData = supplyDataByItem[_itemId];
        supplyData.addrToShipping[_sender] = _shipping;
    }

    function getSupplyAddrToStock(uint256 _itemId, address _sender) public view returns(uint256){
        Supply storage supplyData = supplyDataByItem[_itemId];
        return supplyData.addrToStock[_sender];
    }

    function productTracing(uint256 _itemId, address _root) public view returns(string[] memory){
        address producer = IC.getProducerById(_itemId);
        string[] memory path = new string[] (1); 
        Supply storage supplyData = supplyDataByItem[_itemId];

        path[0] = supplyData.addrToShipping[_root];

        require(bytes(path[0]).length != 0, "There is no record of the transaction.\n");

        while(true){
            if(_root == producer) break;

            _root = supplyData.addrTracing[_root];
            MC.strArrayPush(path, supplyData.addrToShipping[_root]);
         }

         return path;
    }

    function productTracingFromYou(uint256 _itemId) public view returns(string[] memory){
         return productTracing(_itemId, msg.sender);
    }

    function fullLengthTracing(uint256 _itemId) public view returns(string[] memory){

            address[] memory addrList = IC.getOwnerList(_itemId);

            return productTracing(_itemId, addrList[addrList.length-1]);

    }

    function handOver(Shared.Item memory _myItem,  address _owner, address _bidder, 
        uint256 _sales, string memory _shippingAddress) public returns(bool){
                
        uint256 _itemId = _myItem.itemId;

        Supply storage supplyData = supplyDataByItem[_itemId];
        

        uint256 ownerStock = supplyData.addrToStock[_owner];
        uint256 bidderStock = supplyData.addrToStock[_bidder];

        if(bidderStock == 0){
            MC.addrArrayPush(_myItem.itemOwner,_bidder);
            MC.uint256ArrayPush(itemOwned[_bidder], _itemId);
            supplyData.addrTracing[_bidder] = _owner;
            supplyData.addrToShipping[_bidder] = _shippingAddress;
        }


        bidderStock += _sales;
        ownerStock  -= _sales;

        supplyData.addrToStock[_bidder] = bidderStock;
        supplyData.addrToStock[_owner ] = ownerStock;


        if(ownerStock == 0){
            MC.addrArrayErase(_myItem.itemOwner, _owner);

            delete supplyData.addrToStock[_owner];
            delete supplyData.addrToOwnerIdx[_owner];
        }

        supplyData.isShipping[_bidder] = true;


        emit HandOverEvent(_owner, _bidder, _sales);

        return true;
    }

    event productTracingCompleted(uint _itemId, address _root);
    event DontWorryBeHappy(uint256 _itemId, address _bidder);
    event HandOverEvent(address _owner, address _bidder, uint256 _sales);

}