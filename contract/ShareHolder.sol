// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ShareHolder is Ownable {

    uint private _taskID;
    using Counters for Counters.Counter;
    using SafeMath for uint;

    Counters.Counter public _mainTaskCounter;
    Counters.Counter public _subTaskCounter;

    struct Shares {
        uint taskID;
        address address_;
        uint256 shareHoldingAmount;
        bool active;
    }

    struct Task{
        uint id;
        address owner;
        string name;
        bool isMainTask;
        bool active;
    }

    mapping(address => Task[]) private _mainTasks;
    mapping(uint => mapping(address => Task[])) private _subTasks;
    mapping(address => Shares[]) private _sharesMainTask;
    mapping(address => Shares[]) private _sharesSubTask;
    mapping(address => uint256) balances;

    /* EVENTS */
    event MainTaskCreated(
        uint id,
        address owner,
        string name,
        bool isMainTask,
        bool active
    );

    event Received(uint256 amount);
    event MainTaskDeactivated(uint id, uint256 timestamp);
    event ShareHolderAddedToMainTask(uint taskID, address address_, uint256 shareHoldingAmount, bool active);
    event WithdrawedAll(uint256 amount, uint256 time);
    /* EVENTS */

    /* WITHDRAW */
    uint256 private collectedFee;
    function queryCollectedFee() public view onlyOwner returns (uint256) {
        return collectedFee;
    }
    function withdraw() public onlyOwner returns (bool) {
        require(collectedFee > 0, "There is no collected fee in the contract!");
        // (bool success, ) = address(msg.sender).call{value: address(this).balance}("");
        (bool success, ) = address(msg.sender).call{value: collectedFee}("");
        require(success, "Transfer failed!");
        emit WithdrawedAll(address(this).balance, block.timestamp);
        collectedFee = 0;
        return true;
    }
    /* WITHDRAW */
    
    /* SHARE LISTING */
    function getMainShares(address address_) public view returns (Shares[] memory) {
        return _sharesMainTask[address_];
    }
    function getSingleMainShares(address address_, uint mainTaskID) public view returns (Shares memory) {
        require(_sharesMainTask[address_].length > 0, "Does not exist!");
        return _sharesMainTask[address_][mainTaskID];
    }
    function getAmountOfMainShares(address address_) public view returns (uint) {
        return _sharesMainTask[address_].length;
    }
    /* SHARE LISTING */
    function myBalance() public view returns (uint256) {
        return msg.sender.balance;
    }
    /* MAIN TASKS */
    function addMainTask(string memory name_) public returns (bool result){
        _taskID++;
        _mainTasks[msg.sender].push(Task(_mainTaskCounter.current(), address(msg.sender), name_, true, true));
        emit MainTaskCreated(_mainTaskCounter.current(), address(msg.sender), name_, true, true);
        _mainTaskCounter.increment();
        return (true);
    }
    function getMainTasks(address address_) public view returns (Task[] memory) {
        return _mainTasks[address_];
    }
    function getSingleMainTask(address address_, uint mainTaskID) public view returns (Task memory) {
        require(_mainTasks[address_].length > 0, "Does not exist!");
        return _mainTasks[address_][mainTaskID];
    }
    function getAmountOfMainTasks(address address_) public view returns (uint) {
        return _mainTasks[address_].length;
    }
    function deactivateTheMainTask(uint mainTaskID) public returns (bool) {
        Task storage _task = _mainTasks[msg.sender][mainTaskID];
        require(_task.owner == msg.sender, "You are not the owner of the main task!");
        require(_task.active, "This main task is already deactivated!");
        _task.active = false;
        emit MainTaskDeactivated(mainTaskID, block.timestamp);
        return true;
    }
    function addShareHolderToMainTask(uint mainTaskID, address shareHolderAddress, uint256 shareHoldingAmount) public payable returns (bool) {
        Task storage _task = _mainTasks[msg.sender][mainTaskID];
        require(msg.value >= shareHoldingAmount.mul(110).div(100), "You don't have enough ETH!");
        require(_task.owner == msg.sender, "You are not the owner of the main task!");
        require(_task.active, "This main task is already deactivated!");
        require(shareHolderAddress != address(0) && shareHolderAddress != address(0x0) && shareHolderAddress != address(0xdEaD), "Shareholder address cannot be zero or dead address!");
        _sharesMainTask[shareHolderAddress].push(Shares(mainTaskID, shareHolderAddress, shareHoldingAmount, true));
        collectedFee += shareHoldingAmount.mul(100).div(1000);
        emit ShareHolderAddedToMainTask(mainTaskID, shareHolderAddress, shareHoldingAmount, true);
        return true;
    }
    /* MAIN TASKS */

    // function addSubTask(uint mainTaskID, string memory name_) public {
    //     require(_mainTasks[msg.sender].length > 0, "Does not exist!");
    //     require(_mainTasks[msg.sender][mainTaskID].owner == msg.sender, "MainTask does not exist!");
    //     _subTasks[mainTaskID][msg.sender].push(Task(_subTaskCounter.current(), msg.sender, name_, false, true));
    // }

    // function addShareHolderToMainTask(uint mainTaskID, address address_, uint256 sharePercentage) public {
    //     require(_mainTasks[msg.sender][mainTaskID].owner == msg.sender, "MainTask does not exist!");
    //     require(address_ != address(0x0), "Address is not valid.");
    //     require(sharePercentage > 0 && sharePercentage < 100, "Share percentage must be between 0 and 100.");
    //     _sharesMainTask[address_].push(Shares(mainTaskID, address_, sharePercentage));
    // }

    // function addShareHolderToSubTask(uint mainTaskID, uint subTaskID, address address_, uint256 sharePercentage) public {
    //     require(_subTasks[mainTaskID][msg.sender][subTaskID].owner == msg.sender, "SubTask does not exist!");
    //     require(address_ != address(0x0), "Address is not valid.");
    //     require(sharePercentage > 0 && sharePercentage < 100, "Share percentage must be between 0 and 100.");
    //     _sharesSubTask[address_].push(Shares(subTaskID, address_, sharePercentage));
    // }


    // function getSubTasks(address address_, uint mainID) public view returns (Task[] memory) {
    //     require(_subTasks[mainID][address_].length > 0, "Does not exist!");
    //     return _subTasks[mainID][address_];
    // }


    // function getSingleSubTask(address address_, uint mainTaskID, uint subTaskID) public view returns (Task memory) {
    //     require(_subTasks[mainTaskID][address_].length > 0, "Does not exist!");
    //     require(!_subTasks[mainTaskID][address_][subTaskID].isMainTask, "This is a main task!");
    //     return _mainTasks[address_][mainTaskID];
    // }


    // function getMainShares(address address_) public view returns (Shares[] memory) {
    //     return _sharesMainTask[address_];
    // }
    
    receive() external payable {
        emit Received(msg.value);
    }
}