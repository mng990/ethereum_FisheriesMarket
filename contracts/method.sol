// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "./Supply.sol";

contract MethodContract{
    function uint256ArrayPush(uint256[] memory _arr, uint _uint) public pure returns(bool){
        uint256 len = _arr.length;
        assembly { mstore(_arr, add(mload(_arr), 1)) }
        _arr[len] = _uint;
        return true;
    }
     function addrArrayPush(address[] memory _arr, address _owner) public pure returns(bool){
        uint256 len = _arr.length;
        assembly { mstore(_arr, add(mload(_arr), 1)) }
        _arr[len] = _owner;
        return true;
    }

    function strArrayPush(string[] memory _arr, string memory _str) public pure returns(bool){
        uint256 len = _arr.length;
        assembly { mstore(_arr, add(mload(_arr), 1)) }
        _arr[len] = _str;
        return true;
    }

    function uint256ArrayErase(uint256[] memory _arr, uint256 _idx) public pure returns(bool){
        delete _arr[_idx];
        for(uint256 i = _idx+1; i<_arr.length; i++){
            _arr[i] = _arr[i-1];
        }
        assembly { mstore(_arr, sub(mload(_arr), 1)) }

        return true;
    }
    function addrArrayErase(address[] memory _arr, address _owner) public pure returns(bool){
        for(uint256 i = 0; i<_arr.length; i++){
            if(_arr[i] == _owner){
                delete _arr[i];
                for(uint256 j = i+1; j<_arr.length; j++){
                    _arr[j] = _arr[j+1];
                }
            }
        }
        assembly { mstore(_arr, sub(mload(_arr), 1)) }

        return true;
    }
}