// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "./Supply.sol";

contract AuctionContract {

    rwSupplyData rwData = new rwSupplyData();

    Auction[] public auctions;

    mapping(uint256 => Bid[]) public auctionBids;
    mapping(address => uint[]) public auctionOwner;
            
    mapping(address => uint256[]) public ownedBy;

    struct Bid{
        address payable from;
        uint256 amount;
        string shippingTo;
    }

    struct Auction{
        string name;
        uint blockDeadline;
        uint256 startPrice;
        address payable owner;
        bool active;
        bool finalized;
        uint256 itemId;
        string shippingFrom; 
        string shippingTo;  
    }

    modifier isOwnerAuc(uint _auctionId) {
        require(auctions[_auctionId].owner == msg.sender);
        _;
    }

    function getAllOfAuctions() public view returns(Auction[] memory){
        return auctions;
    }

    function getItemByAuction(uint256 _auctionId) public view returns(uint256){
        return auctions[_auctionId].itemId;
    }

    function getBidsCount(uint _auctionId) public view returns(uint){
        return auctionBids[_auctionId].length;
    }

    function getAuctionsOfOwner(address _owner) public view returns(uint[] memory){
        uint[] memory ownedAuctions = auctionOwner[_owner];
        return ownedAuctions;
    }

    
    function getCurrentBid(uint _auctionId) public view returns(uint256, address, string memory) {
        uint bidsLength =auctionBids[_auctionId].length;

        if(bidsLength > 0){
            Bid memory lastBid = auctionBids[_auctionId][bidsLength - 1];
            return (lastBid.amount, lastBid.from, lastBid.shippingTo);
        }

        return (uint256(0), address(0), string(""));
    }

    function getAuctionOwnerLength(address _owner) public view returns(uint) {
        return auctionOwner[_owner].length;
    }

   
    function getOwnedBy(address _user) public view returns(uint256[] memory){
        uint256[] memory _ownedBy = ownedBy[_user];
        return _ownedBy;
    }

    function pushOwnedBy(uint256 _itemId) public returns(uint256){
        ownedBy[msg.sender].push(_itemId);
        return ownedBy[msg.sender].length;
    }

    function getAuctionById(uint _auctionId) public view returns(
        string memory name,
        uint256 blockDeadline,
        uint256 startPrice,
        address payable owner,
        bool active,
        bool finalized,
        uint256 itemId,
        string memory shippingFrom,
        string memory shippingTo
    ){
        Auction memory auc = auctions[_auctionId];
        return (
            auc.name,
            auc.blockDeadline,
            auc.startPrice,
            auc.owner,
            auc.active,
            auc.finalized,
            auc.itemId,
            auc.shippingFrom,
            auc.shippingTo
        );
    }

    function createAuction(string memory _auctionTitle, uint256 _startPrice, uint256 _itemId, 
        uint _blockDeadline, string memory _shippingFrom) public {
        
        uint256 auctionId = auctions.length;

        Auction memory newAuction;

        newAuction.name = _auctionTitle;
        newAuction.blockDeadline = _blockDeadline;
        newAuction.startPrice = _startPrice;
        newAuction.owner = payable(msg.sender);
        newAuction.active = true;
        newAuction.finalized = false;
        newAuction.itemId = _itemId;
        newAuction.shippingFrom = _shippingFrom;
        newAuction.shippingTo = "none";

        auctions.push(newAuction);
        auctionOwner[msg.sender].push(auctionId);
        rwData.setActiveByItemId(_itemId, true);

    }

    function cancelAuction(uint _auctionId) public isOwnerAuc(_auctionId){
        uint bidsLength = auctionBids[_auctionId].length;

        if(bidsLength > 0){
            Bid memory lastBid = auctionBids[_auctionId][bidsLength -1];
            require(lastBid.from.send(lastBid.amount), "failed to refund.");

        }
    }

    function finalizeAuction(uint256 _auctionId) public returns(uint256){
        Auction memory myAuction = auctions[_auctionId];
        uint256 _itemId = myAuction.itemId;
        uint256 bidsLength = auctionBids[_auctionId].length;
        uint256 timeStamp = block.timestamp;
        

        if(timeStamp < myAuction.blockDeadline){
            revert();
        }
        
        if(bidsLength == 0) {
            cancelAuction(_auctionId);
        }else{

            Bid memory lastBid = auctionBids[_auctionId][bidsLength - 1];
            

            require(myAuction.owner.send(lastBid.amount), "Failed to send either." );
            handover(_auctionId, lastBid.from);
            rwData.setAddrToShippingByItemId(_itemId, myAuction.owner, lastBid.from, myAuction.shippingFrom, lastBid.shippingTo);
            myAuction.shippingTo = lastBid.shippingTo;
            
        }

        auctions[_auctionId].active = false;
        auctions[_auctionId].finalized = true;

        rwData.setActiveByItemId(_itemId, false);
        
        return 0;
    }


    function handover(uint256 _auctionId, address _to) public {
        Auction memory myAuction = auctions[_auctionId];
        address _owner = myAuction.owner; 
        uint256 _itemId = myAuction.itemId;
        uint256[] memory ownedByFrom = ownedBy[_owner];
        uint256 len = ownedByFrom.length;

        ownedBy[_owner][_itemId] = ownedByFrom[len-1];
        ownedBy[_owner].pop();

        ownedBy[_to].push(_itemId);
    }

    function sendNow(address payable _from, uint256 _amount, uint256 _auctionId) public payable returns(bool){
        bool sent = _from.send(_amount); 
        require(sent,"Failed to send either.");
        
        auctions[_auctionId].active = false;
        auctions[_auctionId].finalized = true;

        return sent;
    }


    function bidOnAuction(uint _auctionId, string memory _to) external payable {
        uint256 ethAmountSent = msg.value;

        Auction memory myAuction = auctions[_auctionId];
        require(myAuction.owner != msg.sender, "Owner can't participate auction.");
        require(block.timestamp <= myAuction.blockDeadline, "TIME OVER.");
        
        uint256 bidsLength = auctionBids[_auctionId].length;
        uint256 tempAmount = myAuction.startPrice;
        Bid memory lastBid;
        
        
        if(ethAmountSent < tempAmount){
            revert();
        }

        if(bidsLength > 0){
            lastBid = auctionBids[_auctionId][bidsLength -1];
            tempAmount = lastBid.amount;

            if(ethAmountSent < tempAmount){
                revert();
            }

            require(lastBid.from.send(lastBid.amount), "failed to refund.");
        }
        
        Bid memory newBid;
        newBid.from = payable(msg.sender);
        newBid.amount = ethAmountSent;
        newBid.shippingTo = _to;
        auctionBids[_auctionId].push(newBid);
    }

    function getActiveByItemId(uint256 _itemId) public view returns(bool){
        return rwData.getActiveByItemId(_itemId);
    }

    function createSupplyData(uint256 _itemId) public{
        rwData.constructorSupplyData(_itemId);
    }

    function setActiveByItemId(uint256 _itemId, bool _active) public returns(bool){
        rwData.setActiveByItemId(_itemId, _active);
        return rwData.getActiveByItemId(_itemId);
    }

    function getActiveByAuctionId(uint256 _auctionId) public view returns(bool){
        return auctions[_auctionId].active;
    }

    //추가본_08_01

    function getRwSupplyData() public view returns(rwSupplyData){
        return rwData;
    }

    function getWinnigBid(uint256 auctionId) public view returns(uint256){
        uint256 len = auctionBids[auctionId].length;
        return auctionBids[auctionId][len-1].amount;
    } // 옥션의 최종 낙찰가를 리턴

    //function getPathLenByItemIdAuc(uint256 _itemId) public view returns(uint256){}

    // 비상용 method, rwData = getRwSupplyData로 productTracing 접근이 안될 때

}

contract rwSupplyData {

    mapping(uint256 => SupplyContract) public supplyData;

    function constructorSupplyData(uint256 _itemId) public{
        supplyData[_itemId] = new SupplyContract();
    }

    function getPathMaxByItemId(uint256 _itemId) public view returns(string[] memory){
        return supplyData[_itemId].getPathMax();
    }

    function getPathLenByItemId(uint256 _itemId) public view returns(uint256){
        return supplyData[_itemId].getPathLenByAddr(msg.sender);
    }

    function getShippingAddrByItemId(uint256 _itemId, uint256 _idx) public view returns(string memory){
        return supplyData[_itemId].getShippingAddrByIdx(_idx);
    }

    function setAddrToShippingByItemId(uint256 _itemId, address _from, address _to, 
        string memory _fromStr, string memory _toStr) public{
        supplyData[_itemId].setAddrToShippingAddr(_from, _to, _fromStr, _toStr);
    }
    
    function getActiveByItemId(uint256 _itemId) public view returns(bool){
        return supplyData[_itemId].getActive();
    }

    function setActiveByItemId(uint256 _itemId, bool _active) public returns(bool){
        return supplyData[_itemId].setActive(_active);
    }

}