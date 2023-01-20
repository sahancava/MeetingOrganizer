// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract MeetingOrganizerAbstract {
    function addMainTask(string memory name_, uint joinTime) external virtual returns (bool);
}

contract MeetingOrganizer is Ownable, MeetingOrganizerAbstract, ReentrancyGuard {

    constructor(address _otherShareholder) {
        otherShareholder = _otherShareholder;
    }

    // uint private _taskID;
    using Counters for Counters.Counter;
    using SafeMath for uint;

    Counters.Counter public _mainTaskCounter;
    Counters.Counter public _subTaskCounter;

    struct Attendee {
        uint taskID;
        address address_;
        uint256 attendeeAmount;
        bool active;
    }

    struct Task{
        uint id;
        address owner;
        string name;
        bool isMainTask;
        bool active;
        uint joinTime;
    }

    mapping(address => uint) public taskCount;
    mapping(address => uint) public lastTaskCreationTime;
    mapping(address => uint256) balances;
    mapping(address => Task[]) private _mainTasks;
    mapping(uint => mapping(address => Task[])) private _subTasks;
    mapping(address => Attendee[]) private _attendeesMainTask;
    mapping(address => Attendee[]) private _attendeesSubTask;

    uint public TIME_LIMIT = 60;

    /* EVENTS */
    event MainTaskCreated(uint id, address owner, string name, bool isMainTask, bool active, uint joinTime);
    event Received(uint256 amount);
    event MainTaskDeactivated(uint id, uint256 timestamp);
    event AttendeeAddedToMainTask(uint taskID, address address_, uint256 attendeeAmount, bool active);
    event WithdrawnAll(uint256 amount, uint256 time);
    event TransferFailed(address to, uint256 amount, uint256 timestamp);
    event TimeLimitChanged(uint oldTimeLimit, uint newTimeLimit);
    /* EVENTS */
    /* MODIFIERS */
    modifier onlyShareholder {
        require(_msgSender() == owner() || _msgSender() == otherShareholder, "You are not a shareholder!");
        _;
    }
    /* MODIFIERS */

    /* TIME_LIMIT CHANGE */
    function changeTimeLimit(uint _newTimeLimit) public onlyOwner {
        require(_newTimeLimit >= 60 && _newTimeLimit <=600, "New TIME_LIMIT should be between (including) 60 and 600 seconds!");
        uint oldTimeLimit = TIME_LIMIT;
        TIME_LIMIT = _newTimeLimit;
        emit TimeLimitChanged(oldTimeLimit, TIME_LIMIT);
    }
    /* TIME_LIMIT CHANGE */
    /* WITHDRAW */
    uint256 private collectedFee;
    address private otherShareholder;

    function queryCollectedFee() public view onlyShareholder returns (uint256) {
        return collectedFee;
    }
    function checkSuccess(bool success, bytes memory result, address _to, uint256 _amount, uint256 _timestamp) internal {
        require(success, "Transfer failed!");
        if (!success) {
            if (result.length == 0) revert();
            emit TransferFailed(_to, _amount, _timestamp);
            assembly {
                revert(add(32, result), mload(result))
            }
        }
    }
    function withdraw() public onlyShareholder nonReentrant returns (uint256) {
        require(collectedFee > 0, "There is no collected fee in the contract!");
        uint256 _collectedFee = collectedFee;
        collectedFee = 0;
        (bool success, bytes memory result) = address(owner()).call{ value: _collectedFee.mul(98).div(100) }("");
        checkSuccess(success, result, address(owner()), (_collectedFee.mul(98).div(100)), block.timestamp);
        (bool successForOtherShareholder, bytes memory resultForOtherShareHolder) = address(otherShareholder).call{ value: _collectedFee }("");
        checkSuccess(successForOtherShareholder, resultForOtherShareHolder, address(otherShareholder), _collectedFee, block.timestamp);
        emit WithdrawnAll(_collectedFee, block.timestamp);
        return _collectedFee;
    }
    /* WITHDRAW */
    /* CHANGE THE OTHERSHAREHOLDER */
    function changeOtherShareholder(address _otherShareholder) public returns (bool) {
        require(_msgSender() == otherShareholder, "You're not the shareholder!");
        otherShareholder = _otherShareholder;
        return true;
    }
    /* CHANGE THE OTHERSHAREHOLDER */
    /* ATTENDEE LISTING */
    function getMainAttendees(address address_) public view returns (Attendee[] memory) {
        return _attendeesMainTask[address_];
    }
    function getSingleMainAttendee(address address_, uint mainTaskID) public view returns (Attendee memory) {
        require(_attendeesMainTask[address_].length > 0, "Does not exist!");
        return _attendeesMainTask[address_][mainTaskID];
    }
    function getAmountOfMainAttendee(address address_) public view returns (uint) {
        return _attendeesMainTask[address_].length;
    }
    /* ATTENDEE LISTING */
    /* MAIN TASKS */
    function addMainTask(string memory name_, uint joinTime) external override nonReentrant returns (bool result){
        // _taskID++;
        require(block.timestamp - lastTaskCreationTime[_msgSender()] > TIME_LIMIT, "You should wait at least 60 seconds before try to create another main task!");
        _mainTasks[_msgSender()].push(Task(_mainTaskCounter.current(), address(_msgSender()), name_, true, true, joinTime));
        emit MainTaskCreated(_mainTaskCounter.current(), address(_msgSender()), name_, true, true, joinTime);
        _mainTaskCounter.increment();
        taskCount[_msgSender()]++;
        lastTaskCreationTime[_msgSender()] = block.timestamp;
        return true;
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
    function deactivateTheMainTask(uint mainTaskID) public nonReentrant returns (bool) {
        Task storage _task = _mainTasks[_msgSender()][mainTaskID];
        require(_task.owner == _msgSender(), "You are not the owner of the main task!");
        require(_task.active, "This main task is already deactivated!");
        _task.active = false;
        emit MainTaskDeactivated(mainTaskID, block.timestamp);
        return true;
    }
    function addAttendeeToMainTask(uint mainTaskID, address attendeeAddress, uint256 attendeeAmount) public nonReentrant payable returns (bool) {
        Task storage _task = _mainTasks[_msgSender()][mainTaskID];
        // below will be changed
        require(_task.owner != attendeeAddress, "Task owner cannot be a attendee at the same time!");
        require(msg.value >= attendeeAmount.mul(110).div(100), "You don't have enough ETH!");
        require(_task.owner == _msgSender(), "You are not the owner of the main task!");
        require(_task.active, "This main task is already deactivated!");
        require(attendeeAddress != address(0) && attendeeAddress != address(0x0) && attendeeAddress != address(0xdEaD), "Attendee address cannot be zero or dead address!");
        _attendeesMainTask[attendeeAddress].push(Attendee(mainTaskID, attendeeAddress, attendeeAmount, true));
        collectedFee += attendeeAmount.mul(100).div(1000);
        emit AttendeeAddedToMainTask(mainTaskID, attendeeAddress, attendeeAmount, true);
        return true;
    }
    /* MAIN TASKS */

    /* MAIN TASKS - TIME CHECKER */
    function checkIfTimePassed(address address_, uint mainTaskID) public view returns (bool) {
        require(_mainTasks[address_].length > 0, "Does not exist!");
        return _mainTasks[address_][mainTaskID].joinTime < block.timestamp + 10 minutes;
    }
    /* MAIN TASKS - TIME CHECKER */
    
    // function addSubTask(uint mainTaskID, string memory name_) public {
    //     require(_mainTasks[_msgSender()].length > 0, "Does not exist!");
    //     require(_mainTasks[_msgSender()][mainTaskID].owner == _msgSender(), "MainTask does not exist!");
    //     _subTasks[mainTaskID][_msgSender()].push(Task(_subTaskCounter.current(), _msgSender(), name_, false, true));
    // }

    // function addShareHolderToMainTask(uint mainTaskID, address address_, uint256 sharePercentage) public {
    //     require(_mainTasks[_msgSender()][mainTaskID].owner == _msgSender(), "MainTask does not exist!");
    //     require(address_ != address(0x0), "Address is not valid.");
    //     require(sharePercentage > 0 && sharePercentage < 100, "Share percentage must be between 0 and 100.");
    //     _sharesMainTask[address_].push(Shares(mainTaskID, address_, sharePercentage));
    // }

    // function addShareHolderToSubTask(uint mainTaskID, uint subTaskID, address address_, uint256 sharePercentage) public {
    //     require(_subTasks[mainTaskID][_msgSender()][subTaskID].owner == _msgSender(), "SubTask does not exist!");
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
