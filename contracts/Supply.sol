// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "./Item.sol";
import "./method.sol";

contract SupplyContract{

    ItemContract IC;
    MethodContract MC;

    mapping(address => bool     ) public producerCheck;
    mapping(address => uint256[]) public itemOwned;
    mapping(uint256 => Supply   ) supplyDataByItem;

    

    struct Supply{
        mapping(address => address) addrTracing;   // 경로 추적 
        mapping(address => string ) addrToShipping;  // 유저별 주소
        mapping(address => uint256 ) addrToStock;    // 유저별 소유량
        mapping(address => uint256 ) addrToOwnerIdx; // 유저별 index
        mapping(address => bool    ) isShipping;
    }

    function deleveryCompleted(uint256 _itemId, address payable _bidder) public returns(bool){
        supplyDataByItem[_itemId].isShipping[_bidder] = false;
        emit DontWorryBeHappy(_itemId, _bidder);
        return true;
    }

    function setSupplyAddrToStock(uint256 _itemId, address payable _sender, uint256 _sales) public{
        supplyDataByItem[_itemId].addrToStock[_sender] = _sales;
    }

    function setSupplyAddrToShippingAddr(uint256 _itemId, address payable _sender, string memory _shipping) public{
        supplyDataByItem[_itemId].addrToShipping[_sender] = _shipping;
    }

    function getSupplyAddrToStock(uint256 _itemId, address _sender) public view returns(uint256){
        return supplyDataByItem[_itemId].addrToStock[_sender];
    }

    function productTracing(uint256 _itemId, address _root) public view returns(string[] memory){
        address producer = IC.getProducerById(_itemId);
        string[] memory path = new string[] (1); 
        path[0] = supplyDataByItem[_itemId].addrToShipping[_root];

        require(bytes(path[0]).length != 0, "There is no record of the transaction.\n");

        while(true){
            if(_root == producer) break;

            _root = supplyDataByItem[_itemId].addrTracing[_root];
            MC.strArrayPush(path, supplyDataByItem[_itemId].addrToShipping[_root]);
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
        
        

        uint256 ownerStock = supplyDataByItem[_itemId].addrToStock[_owner];
        uint256 bidderStock = supplyDataByItem[_itemId].addrToStock[_bidder];

        if(bidderStock == 0){
            MC.addrArrayPush(_myItem.itemOwner,_bidder);
            MC.uint256ArrayPush(itemOwned[_bidder], _itemId);
            supplyDataByItem[_itemId].addrTracing[_bidder] = _owner;
            supplyDataByItem[_itemId].addrToShipping[_bidder] = _shippingAddress;
        }


        bidderStock += _sales;
        ownerStock  -= _sales;

        supplyDataByItem[_itemId].addrToStock[_bidder] = bidderStock;
        supplyDataByItem[_itemId].addrToStock[_owner ] = ownerStock;


        if(ownerStock == 0){
            MC.addrArrayErase(_myItem.itemOwner, _owner);

            delete supplyDataByItem[_itemId].addrToStock[_owner];
            delete supplyDataByItem[_itemId].addrToOwnerIdx[_owner];
        }

        supplyDataByItem[_itemId].isShipping[_bidder] = true;


        emit HandOverEvent(_owner, _bidder, _sales);

        return true;
    }

    event productTracingCompleted(uint _itemId, address _root);
    event DontWorryBeHappy(uint256 _itemId, address _bidder);
    event HandOverEvent(address _owner, address _bidder, uint256 _sales);

}