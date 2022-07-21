// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "./Item.sol";
import "./Supply.sol";

contract AuctionContract{
    Auction[] public auctions;

    ItemContract   IC;
    SupplyContract SC;

    mapping(uint256 => Bid[]) public auctionBids;
    mapping(address => uint[]) public auctionOwner;
    mapping(address => uint[]) public auctionSuccessfulBidder;




    struct Bid{
        address payable from;
        uint256 amount;
        string shippingAddress;
    }

    struct Auction{
        string name;
        uint256 blockDeadline;
        uint256 startPrice;
        address payable owner;
        address payable successfulBidder;
        //string imgPath; // 이미지 데이터 해시값, ipfs와 통신 
        bool active;
        bool finalized;
        string shippingAddress;
        uint256 itemId;
        uint256 sales;

    }

    modifier isOwner(uint _auctionId) {
        require(auctions[_auctionId].owner == msg.sender);
        _;
    }

    function isOwned(address[] memory _itemOwner) public view returns(bool){
        for(uint256 i=0;i<_itemOwner.length;i++){
            if(_itemOwner[i]==msg.sender){
                return true;
            }
             
        }
        return false;
    }



    function getBidsCount(uint _auctionId) public view returns(uint){
        return auctionBids[_auctionId].length;
    }

    function getAuctionsOfOwner(address _owner) public view returns(uint[] memory){
        uint[] memory ownedAuctions = auctionOwner[_owner];
        return ownedAuctions;
    }

    function getAuctionsOfSuccessfulBidder(address _successfulBidder) public view returns(uint[] memory){
        uint[] memory successAuctions = auctionSuccessfulBidder[_successfulBidder];
        return successAuctions;
    }
    function getCurrentBid(uint _auctionId) public view returns(uint256, address, string memory) {
        uint bidsLength =auctionBids[_auctionId].length;

        if(bidsLength > 0){
            Bid memory lastBid = auctionBids[_auctionId][bidsLength - 1];
            return (lastBid.amount, lastBid.from, lastBid.shippingAddress);
        }

        return (uint256(0), address(0), string(""));
    }

    function getAuctionsCountOfOwner(address _owner) public view returns(uint) {
        return auctionOwner[_owner].length;
    }

    function getAuctionsCountOfSuccessfulBidder(address _successfulBidder) public view returns(uint) {
        return auctionSuccessfulBidder[_successfulBidder].length;
    }

//수정
    function getAuctionById(uint _auctionId) public view returns(
        string memory name,
        uint256 blockDeadline,
        uint256 startPrice,
        address payable owner,
        address payable successfulBidder,
        //string imgPath; // 이미지 데이터 해시값, ipfs와 통신 
        bool active,
        bool finalized,
        //uint256 itemId;
        uint256 itemId,
        uint256 sales
    ){
        Auction memory auc = auctions[_auctionId];
        return (
            auc.name,
            auc.blockDeadline,
            auc.startPrice,
            auc.owner,
            auc.successfulBidder,
            //auc.imgPath,
            auc.active,
            auc.finalized,
            auc.itemId,
            auc.sales
        );
    }

    // 경매 생성
    function createAuction(string memory _auctionTitle, uint256 _startPrice, uint256 _itemId, 
        uint _blockDeadline, uint256 _sales, string memory _shippingAddr) public {
        
        uint256 auctionId = auctions.length;
        uint256 stock = SC.getSupplyAddrToStock(_itemId, msg.sender);
        require(_sales <= stock, "Out Of Stock.\n");

        Auction memory newAuction;
        newAuction.name = _auctionTitle;
        newAuction.blockDeadline = _blockDeadline;
        newAuction.startPrice = _startPrice;
        newAuction.owner = payable(msg.sender);
        //newAuction.imgPath = _imgPath;
        newAuction.active = true;
        newAuction.finalized = false;
        newAuction.itemId = _itemId;
        newAuction.sales = _sales;
        newAuction.shippingAddress = _shippingAddr;

        
        
        SC.setSupplyAddrToShippingAddr(_itemId, payable(msg.sender), _shippingAddr);

        auctions.push(newAuction);
        auctionOwner[msg.sender].push(auctionId);
        
        emit AuctionCreated(msg.sender, auctionId);        
    }

    // 경매 취소
    function cancelAuction(uint _auctionId) public isOwner(_auctionId){
        uint bidsLength = auctionBids[_auctionId].length;
        bool sent;

        if(bidsLength > 0){
            Bid memory lastBid = auctionBids[_auctionId][bidsLength -1];
            sent = lastBid.from.send(lastBid.amount);
            if(!sent){
                revert();
            }
            auctions[_auctionId].active = false;
            emit AuctionCanceled(lastBid.from, _auctionId);
        }
    }

    function finalizeAuction(uint _auctionId) public {
        Auction memory myAuction = auctions[_auctionId];
        uint bidsLength = auctionBids[_auctionId].length;

        if( block.timestamp < myAuction.blockDeadline ) revert();
        
        if(bidsLength == 0) {
            cancelAuction(_auctionId);
        }else{

            Bid memory lastBid = auctionBids[_auctionId][bidsLength - 1];
            

            if(sendNow(lastBid.from, lastBid.amount, _auctionId)){
                auctions[_auctionId].successfulBidder = lastBid.from;
                Shared.Item memory aucItem = IC.getItemById(myAuction.itemId);
                SC.handOver(aucItem, msg.sender, lastBid.from, 
                myAuction.sales,lastBid.shippingAddress);
            }
            
        }
    }

    function sendNow(address payable _from, uint256 _amount, uint256 _auctionId) public payable returns(bool){
        bool sent = _from.send(_amount); // return true or false
        require(sent,"Failed to send either.\n");
        
        auctions[_auctionId].active = false;
        auctions[_auctionId].finalized = true;
        emit AuctionFinalized(_from, _auctionId);
        emit howMuch(_amount);

        return sent;
    }


    // 입찰
    function bidOnAuction(uint _auctionId, string memory _shippingAddress) external payable {
        uint256 ethAmountSent = msg.value;

        Auction memory myAuction = auctions[_auctionId];
        if(myAuction.owner == msg.sender) revert();

        if(block.timestamp > myAuction.blockDeadline) revert();
        uint bidsLength = auctionBids[_auctionId].length;
        uint256 tempAmount = myAuction.startPrice;
        Bid memory lastBid;

        if(bidsLength > 0){
            lastBid = auctionBids[_auctionId][bidsLength -1];
            tempAmount = lastBid.amount;
        }

        if(ethAmountSent < tempAmount) revert();

        if(bidsLength > 0){
            if(!lastBid.from.send(lastBid.amount)){
                revert();
            }
        }

        Bid memory newBid;
        newBid.from = payable(msg.sender);
        newBid.amount = ethAmountSent;
        newBid.shippingAddress = _shippingAddress;
        auctionBids[_auctionId].push(newBid);
        emit BidSuccess(msg.sender, _auctionId);
    }

    event BidSuccess(address _from, uint _auctionId);
    event AuctionCreated(address _owner, uint _auctionId);
    event AuctionCanceled(address _owner, uint _auctionId);
    event AuctionFinalized(address _owner, uint _auctionId);
    event howMuch(uint256 _value);


}