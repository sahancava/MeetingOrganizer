// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

contract MaliciousReentrancy {
    address target;

    constructor(address _target) {
        target = _target;
    }

    function call() public payable {
        for(uint i=0;i<5;i++) {
            (bool success,) = target.call{value: address(this).balance}("");
            require(success, "transfer failed");
        }
    }
}

