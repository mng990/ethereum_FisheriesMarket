// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "./method.sol";
import "./Supply.sol";

library Shared{
    struct Item{
        string name;    // 상품명
        uint256 weight; // 무게
        uint256 stock;      // 재고
        address payable producer;   // 생산자
        string origin;  // 원산지
        uint256 itemId;    // Item Array Index
        address[] itemOwner;
    }
    
}

contract ItemContract{

    SupplyContract SC;
    MethodContract MC;

    Shared.Item[] public items;

    
    

    mapping(address => bool     ) public producerCheck;
    mapping(address => uint256[]) public itemOwned;
    


    function createItem(string memory _itemTitle, uint256 _weight, uint256 _stock, 
        string memory _origin) public isProducer(msg.sender) returns(bool){
        
        uint256 _itemId = items.length;
        
        Shared.Item memory newItem;
        
        newItem.name = _itemTitle;
        newItem.weight = _weight;
        newItem.stock = _stock;
        newItem.producer = payable(msg.sender);
        newItem.origin = _origin;
        newItem.itemId = _itemId;
        
        SC.setSupplyAddrToStock(_itemId, payable(msg.sender), _stock);
        MC.addrArrayPush(newItem.itemOwner, msg.sender);
        items.push(newItem);
        itemOwned[msg.sender].push(_itemId);
        emit CreateItemEvent(_itemTitle, _weight, _stock, _origin);
        return true;
    }

    function getOwnerList(uint256 _itemId) public view returns(address[] memory _itemOwner){
        return items[_itemId].itemOwner;
    }

    function getProducerById(uint256 _itemId) public view returns(address _proudcer){
        return items[_itemId].producer;
    }

    function getItemOwned() public view returns(uint256[] memory){
        return itemOwned[msg.sender];
    }
    
    function viewItemById(uint _itemId) public view returns(
        string memory name,
        uint256 weight,
        uint256 stock,
        address payable producer,
        string memory origin,
        uint256 itemId,
        address[] memory itemOwner

    ){
        Shared.Item memory item = items[_itemId];
        return(
            item.name,
            item.weight,
            item.stock,
            item.producer,
            item.origin,
            item.itemId,
            item.itemOwner
        );
    }

    function getItemById(uint _itemId) public view returns(Shared.Item memory){
        return items[_itemId];
    }


    modifier isProducer(address _owner){
        require(producerCheck[_owner] == true);
        _;
    }

    function setOwnerToProducer(address _owner, bool flag) public returns(bool){
        producerCheck[_owner] = flag;
        emit SetOwnerToProducerEvent(_owner, flag);
        return true;
    }
    

    event SetOwnerToProducerEvent(address _owner, bool flag);
    event CreateItemEvent(string _itemTitle, uint256 _weight, uint256 _stock, string _origin);
}