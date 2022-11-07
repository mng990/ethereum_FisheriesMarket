// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "./Supply.sol";
import "./Item.sol";

contract AuctionContract is ERC1155 {
  

    ItemContract internal _itemContract;

    SupplyContract internal _supplyContract;

    address payable internal _governance;

    uint256 internal _auctionId;

    string[2] internal _baseURI = ["https://ipfs.io/ipfs/", "/{id}.json"];

    mapping(uint256 => Bid[] ) public _auctionBids;
    mapping(uint256 => string) internal _shippingFrom; // auctionId => shipping address
    mapping(address => mapping(uint256 => uint256[][])) _aucMap; // map[buyer][itemId] = aucDP[];
    mapping(uint256 => address) internal _sellerOf;

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }


    constructor(address itemAddress, address supplyAddress, string memory dirCID) ERC1155(string.concat(string.concat(_baseURI[0], dirCID), _baseURI[1]))
    {
        _auctionId = 1;
        _itemContract = ItemContract(itemAddress);
        _supplyContract = SupplyContract(supplyAddress);
        _governance = payable(msg.sender);
    }
    
    struct Bid{
        address payable from;
        uint256 amount;
        uint256 timestamp;
        string shippingTo;
    }


    modifier onlySeller(uint256 auctionId) {
        require(msg.sender == _sellerOf[auctionId]);
        _;
    }

    modifier onlyOwner(uint256 itemId){
        require(_itemContract.balanceOf(msg.sender, itemId)>0);
        _;
    }

    modifier onlyGovernance(){
        require(payable(msg.sender) == _governance);
        _;
    }


    function getAuctionId() public view returns(uint256){
        return _auctionId;
    }

    function getBidsCount(uint256 auctionId) public view returns(uint256){
        return _auctionBids[auctionId].length;
    }
    
    function getCurrentBid(uint256 auctionId) public view returns(uint256) {
        uint256 bidsLength = _auctionBids[auctionId].length;

        if(bidsLength > 0){
            Bid memory lastBid = _auctionBids[auctionId][bidsLength - 1];
            return (lastBid.amount);
        }

        return (uint256(0));
    }

    function createAuction(uint256 itemId, uint256 stock, string memory shippingFrom, string memory dirCID) public onlyOwner(itemId){
        string memory newURI = string.concat(string.concat(_baseURI[0], dirCID), _baseURI[1]);
        _setURI(newURI);
        _mint(_governance, _auctionId, 1, "");
        //_mint(_governance, _auctionId++, 1, "");
        _itemContract.safeTransferFrom(msg.sender, _governance, itemId, stock, "");
        _sellerOf[_auctionId] = msg.sender;
        _shippingFrom[_auctionId] = shippingFrom;
        _auctionId++;
    }

    function cancelAuction(uint256 auctionId, uint256 itemId, address seller, uint256 stock) public onlySeller(auctionId){
        uint256 bidsLength = _auctionBids[auctionId].length;

        if(bidsLength > 0){
            Bid memory lastBid = _auctionBids[auctionId][bidsLength -1];
            _itemContract.safeTransferFrom(_governance, lastBid.from, 0, lastBid.amount, "");
        }
        _itemContract.safeTransferFrom(_governance, seller, itemId, stock, "");
        _burn(_governance, auctionId, 1);
        _sellerOf[auctionId] = address(0);
        delete _shippingFrom[auctionId];
    }

    function finalizeAuction(uint256 auctionId, uint256 itemId, address seller, uint256 stock, 
    uint256 blockDeadline, string memory dirCID) public onlySeller(auctionId) {
        uint256 bidsLength = _auctionBids[auctionId].length;
        uint256 timeStamp = block.timestamp;

        string memory newURI = string.concat(string.concat(_baseURI[0], dirCID), _baseURI[1]);
        _setURI(newURI);
        //address payable aucOwner = ownerDataContract.getOwnerByAucId(auctionId);
        

        if(timeStamp < blockDeadline){
            revert();
        }
        
        if(bidsLength == 0) {
            cancelAuction(auctionId, itemId, seller, stock);
        }else{

            Bid memory lastBid = _auctionBids[auctionId][bidsLength - 1];

            _setApprovalForAll(lastBid.from, msg.sender, true);
            _setApprovalForAll(_governance, msg.sender, true);


            _itemContract.safeTransferFrom(_governance, msg.sender, 0, lastBid.amount, "");
            _itemContract.safeTransferFrom(_governance, lastBid.from, itemId, stock, "");
            safeTransferFrom(_governance, seller, auctionId, 1, "");
            safeTransferFrom(seller, lastBid.from, auctionId, 1, "");

            _setApprovalForAll(lastBid.from, msg.sender, false);
            _setApprovalForAll(_governance, msg.sender, false);
            updateMap(auctionId, itemId, seller, lastBid.from);
            _supplyContract.deliveryPrepareByAuctionId(auctionId);
        }
    }

    function bidOnAuction(uint256 auctionId, uint256 amount, uint256 startPrice, uint256 startTime, uint256 blockDeadline, string memory shippingTo) external payable {
        uint256 timestamp = block.timestamp;

        require(startTime<=timestamp && timestamp <= blockDeadline);
        
        uint256 bidsLength = _auctionBids[auctionId].length;
        uint256 tempAmount = startPrice;
        Bid memory lastBid;
        
        require(tempAmount <= amount, "Lower than start price");

        _itemContract.safeTransferFrom(msg.sender, _governance, 0, amount, "");

        if(bidsLength > 0){
            lastBid = _auctionBids[auctionId][bidsLength -1];
            tempAmount = lastBid.amount;

            require(amount > tempAmount, "Lower than currentBid");

            _itemContract.safeTransferFrom(_governance, lastBid.from, 0, lastBid.amount, "");
        }
        
        Bid memory newBid;
        newBid.shippingTo = shippingTo;
        newBid.from = payable(msg.sender);
        newBid.amount = amount;
        newBid.timestamp = timestamp;
        _auctionBids[auctionId].push(newBid);
    }

    function updateMap(uint256 auctionId, uint256 itemId, address seller, address buyer) public{
        uint256 loop = _aucMap[seller][itemId].length;
        if(loop == 0){
            uint256[1] memory newRow = [auctionId];
            _aucMap[buyer][itemId].push(newRow);
            return;
        }
        for(uint256 i=0; i<_aucMap[seller][itemId].length; i++){
            uint256 mlen = _aucMap[buyer][itemId].length;
            _aucMap[buyer][itemId].push(_aucMap[seller][itemId][i]);
            _aucMap[buyer][itemId][mlen].push(auctionId); 
        }

        return;
    }   

    function getMapOfUser(uint256 itemId) public view returns(uint256[][] memory){
        return _aucMap[msg.sender][itemId];
    }

    function getWinningPrice(uint256 auctionId) public view returns(uint256){
        uint256 len = _auctionBids[auctionId].length;
        return _auctionBids[auctionId][len-1].amount;
    } // 옥션의 최종 낙찰가를 리턴

    function getBidderInfo(uint256 auctionId) public view returns(Bid memory){
        Bid[] memory BidArr = _auctionBids[auctionId];
        return _auctionBids[auctionId][BidArr.length-1];
    }

    function setGovernance() public onlyGovernance(){
        _governance = payable(address(this));
    }

    function getGovernance() public view returns(address payable){
        return _governance;
    }

    function getDeliveryList() public view returns(uint256[] memory){
        uint256[] memory deliveryList = new uint256[](_auctionId);
        uint256 listIdx = 0;
        for(uint256 i=0; i<_auctionId; i++){
            if(_supplyContract.inDelivery(i)){
                deliveryList[listIdx] = i;
                listIdx++;
            }
        }

        return deliveryList;
    }

}

