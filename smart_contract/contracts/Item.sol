// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "./Auction.sol";

contract ItemContract{

    struct Item{
        string name;
        uint256 weight; 
        uint256 stock;     
        address payable producer;   
        string origin;  
        uint256 itemId;    
        string imgCID;
        address payable owner;
        bool active;
    } 

    Item[] public items;


    mapping(address => bool     ) public producerCheck;
    mapping(uint256 => uint256[]) public auctionTracking;
    


    function createItem(string memory _itemTitle, uint256 _weight, uint256 _stock,  string memory _origin) public returns(uint256){
        
        uint256 _itemId = items.length;

        
        Item memory newItem;
        
        newItem.name = _itemTitle;
        newItem.weight = _weight;
        newItem.stock = _stock;
        newItem.producer = payable(msg.sender); 
        newItem.origin = _origin;
        newItem.itemId = _itemId;
        newItem.owner = payable(msg.sender);

        items.push(newItem);
 
        emit CreateItemEvent(_itemTitle, _weight, _stock, _origin);
        return _itemId;
    }

    function getStockById(uint256 _itemId) public view returns(uint256){
        return items[_itemId].stock;
    }

    function getAllOfItems() public view returns(Item[] memory){
        return items;
    }
    
    function getProducerCheck(address _user) public view returns(bool){
        bool rtn = producerCheck[_user];
        return rtn;
    }

    function getOriginById(uint256 _itemId) public view returns(string memory){
        return items[_itemId].origin;
    }    

    function getProducerById(uint256 _itemId) public view returns(address _proudcer){
        return items[_itemId].producer;
    }

    function getItemNameById(uint256 _itemId) public view returns(string memory){
        return items[_itemId].name;
    }

    function getBidOrNotById(uint256 _itemId) public view returns(bool){
        return msg.sender != items[_itemId].producer;
    }

    
    function viewItemById(uint _itemId) public view returns(
        string memory name,
        uint256 weight,
        uint256 stock,
        address payable producer,
        string memory origin,
        uint256 itemId
    ){
        Item memory item = items[_itemId];
        return(
            item.name,
            item.weight,
            item.stock,
            item.producer,
            item.origin,
            item.itemId
            );
    }

    function getItemById(uint256 _itemId) public view returns(Item memory){
        return items[_itemId];
    }


    function isProducer() public view returns(bool){
        return producerCheck[msg.sender];
        }
        

    function setOwnerToProducer(bool flag) public returns(bool){
        producerCheck[msg.sender] = flag;
        emit SetOwnerToProducerEvent(flag);
        return producerCheck[msg.sender];
    }
    


    event SetOwnerToProducerEvent(bool flag);
    event CreateItemEvent(string _itemTitle, uint256 _weight, uint256 _stock, string _origin);
}