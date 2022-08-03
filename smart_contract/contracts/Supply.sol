// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

contract SupplyContract{


    mapping(address => address) public addrTracing;    
    mapping(address => string ) public addrToShippingAddr;
    mapping(address => uint256) public addrToPathIdx;
    mapping(uint256 => address) public pathIdxToAddr;


    string[] public pathMax;

    bool active = false;


    mapping(address => bool     ) public producerCheck;

    function getActive() public view returns(bool){
        return active;
    }

    function setActive(bool _active) public returns(bool){
        active = _active;
        return active;
    }

    function setAddrTracing(address _from, address _to) public {
        addrTracing[_to] = _from;
    }

    function getShippingAddrByIdx(uint256 _idx) public view returns(string memory){
        return pathMax[_idx];
    } 

    function getPathLenByAddr(address _user) public view returns(uint256){
        return addrToPathIdx[_user];
    }

    function setAddrToShippingAddr(address _from, address _to, string memory _fromStr, string memory _toStr) public {
        pathIdxToAddr[pathMax.length] = _from;
        addrToPathIdx[_from] = pathMax.length;
        pathMax.push(_fromStr);
        pathIdxToAddr[pathMax.length] = _to;
        addrToPathIdx[_to] = pathMax.length;
        pathMax.push(_toStr);
    }

    function getPathMax() public view returns(string[] memory){
        return pathMax;
    }

    function productTracing(address _user, address _producer) public view returns(string[] memory){
        
        if(_user == _producer) revert();
        uint256 trlen = 0;
        uint256 fullLen = pathMax.length;

        string[] memory path = new string[](fullLen);

        path[trlen++] = addrToShippingAddr[_user];

        while(true){
            _user = addrTracing[_user];
            if(_user == _producer) break;
            
            path[trlen++] = addrToShippingAddr[_user];
         }
        
        if(trlen < fullLen){
            fullLen -= trlen;

            assembly { mstore(path, sub(mload(path), fullLen)) }
        }

         return path;
    }

    function productTracingFromYou(address _producer) public view returns(string[] memory){
        string[] memory path = productTracing(msg.sender, _producer);
        return path;
    }

    event productTracingCompleted(uint _itemId, address _root);
    event DontWorryBeHappy(uint256 _itemId, address _bidder);

}

