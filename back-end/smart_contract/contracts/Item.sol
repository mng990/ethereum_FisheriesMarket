// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

import "../node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract ItemContract is ERC1155 {

    uint256 internal _itemId; //item length

    address payable internal _governance;

    string[2] baseURI = ["https://ipfs.io/ipfs/", "/{id}.json"];

    mapping(uint256 => address) internal _producerOf; // _itemId => producer;
    mapping(address => bool) internal _isProducer;
    mapping(address => bool) internal _isManager;
    mapping(address => uint256[]) internal _mintList;


    constructor(string memory _dirCID) ERC1155(string.concat(string.concat(baseURI[0], _dirCID),baseURI[1])) {
        _itemId = 1;
        _governance = payable(msg.sender);
    }
    
    function getProducerOf(uint256 itemId) external view returns(address){
        return _producerOf[itemId];
    }

    function getIsProducer(address _user) public view returns(bool){
        return _isProducer[_user];
    } 

    function getMsgSender() public view returns(address){
        return msg.sender;
    }

    function getIsManager() public view returns(bool){
        return _isManager[msg.sender];
    }

    function setGovernance(address auctionAddress) public onlyGovernance(){
        _governance = payable(auctionAddress);
        _isProducer[_governance] = true;
        _isManager[_governance] = true;
        _mint(_governance, 0, 10**18, "");
        _mintList[_governance].push(0); 
    }

    function setApprovalForAll(address _owner, address _operator, bool _approved) internal {
        _setApprovalForAll(_owner, _operator, _approved);
    }

    function getGovernance() public view returns(address){
        return _governance;
    }

    function setApprovalForUser(address _user, bool _approved) public{
        require(_governance != address(0));
        if(_user != _governance){
            _setApprovalForAll(_user, _governance, _approved);
            //_setApprovalForAll(_governance, _user, _approved);
        }
    }

    modifier onlyProducer(){
        require(_isProducer[msg.sender] || _governance == msg.sender, "only producer can call this.");
        _;
    }

    modifier onlyGovernance(){
        require(msg.sender == _governance, "only gorvernance can call this");
        _;
    }

    function WeitoMMT(address payable _user) public payable {
        require(msg.value > 0, "This Wei is not enough to buy a MMT.");
        _setApprovalForAll(_governance, _user, true);
        safeTransferFrom  (_governance, _user, 0, msg.value, "");
        _setApprovalForAll(_governance, _user, false);
    }

    function ETHtoMMT(address payable _user) public payable {
        uint256 amount = msg.value/(10**18);
        require(msg.value > 0, "This Wei is not enough to buy a MMT.");
        _setApprovalForAll(_governance, _user, true);
        safeTransferFrom  (_governance, _user, 0, amount, "");
        _setApprovalForAll(_governance, _user, false);
    }

    function MMTtoETH(uint256 amount) public payable {
        require(amount > 0, "Over zero.");
        require(balanceOf(msg.sender, 0) >= amount, "Token is not enough to exchange for a Wei.");
        payable(msg.sender).transfer(amount*(10**18));
        safeTransferFrom(msg.sender, _governance, 0, amount, "");
    } 

    function mintMMT(uint256 _amount) public onlyGovernance(){
        _mint(msg.sender, 0, _amount, "");
    }

    function mintItemByItemId(uint256 stock, uint256 itemId) public onlyProducer(){
        require(itemId <= _itemId, "Unregistered item cannot be produced.");
        require(itemId != 0 || msg.sender == _governance, "Only the government can produce tokens.");
        _mint(msg.sender, itemId, stock, "");
    }

    function getItemId() public view returns(uint256){
        return _itemId;
    }

    function createItem(uint256 amount, string memory dirCID) public onlyProducer(){
        string memory newURI = string.concat(string.concat(baseURI[0], dirCID), baseURI[1]);
        _setURI(newURI);
        _mint(msg.sender, _itemId, amount, "");
        _mintList[msg.sender].push(_itemId);
        _producerOf[_itemId] = msg.sender;
        _itemId++;
    }

    function getURI(uint256 itemId) public view returns(string memory){
        return uri(itemId);
    }

    function burn(uint256 itemId, uint256 _amount) public{
        _burn(msg.sender, itemId, _amount);
    }

    function setUserToProducer(bool flag) public {
        _isProducer[msg.sender] = flag;
    }

    function setUserToManager(bool flag) public {
        _isManager[msg.sender] = flag;
    }

}