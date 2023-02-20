// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MeetingOrganizer is ReentrancyGuard, Ownable {

    address private otherShareholder;
    uint256 private collectedFee;

    /**
     * @dev Returns the other shareholder address.
     */
    function whoIsTheOtherShareHolder() public view returns (address) {
        return otherShareholder;
    }

    constructor(address _otherShareholder) {
        require(_msgSender() != _otherShareholder, "Contract owner cannot be the other shareholder!");
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

    mapping(address _owner => uint _count) public taskCount;
    mapping(address _owner => uint _timestamp) public lastTaskCreationTime;
    mapping(address _owner => uint256 _amount) balances;
    mapping(address _owner => Task[] _mainTask) private _mainTasks;
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
    event OtherShareHolderChanged(uint256 changeTime, address oldAddress, address newAddress);
    /* EVENTS */

    /* ERROR HANDLING */
    error CustomERROR_Not_A_Wallet_Address();
    error CustomERROR_Not_A_ShareHolder();
    error CustomERROR_No_Collected_Fee();
    /* ERROR HANDLING */

    /* TIME_LIMIT CHANGE */
    /**
     * 
     * @param _newTimeLimit The new time limit in seconds
     */
    function changeTimeLimit(uint _newTimeLimit) public onlyOwner {
        require(_newTimeLimit >= 60 && _newTimeLimit <=600, "New TIME_LIMIT should be between (including) 60 and 600 seconds!");
        uint oldTimeLimit = TIME_LIMIT;
        TIME_LIMIT = _newTimeLimit;
        emit TimeLimitChanged(oldTimeLimit, TIME_LIMIT);
    }
    /* TIME_LIMIT CHANGE */

    /* WITHDRAW */
    
    /**
     * @dev Query the collected fee
     * @return collectedFee The collected fee
     * _msgSender() must be the owner or the other shareholder
     */
    function queryCollectedFee() public view returns (uint256) {
        if (_msgSender() != otherShareholder && _msgSender() != owner()) {
            revert CustomERROR_Not_A_ShareHolder();
        }
        return collectedFee;
    }

    /**
     * Internal function to check if the transfer was successful
     * @param success checks if the transfer was successful
     * @param result the result of the transfer
     * @param _to the address to which the transfer was made
     * @param _amount the amount of the transfer
     * @param _timestamp the timestamp of the transfer
     */
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
    function withdraw() public nonReentrant returns (uint256) {
        if (_msgSender() != owner() && _msgSender() != otherShareholder) {
            revert CustomERROR_Not_A_ShareHolder();
        }
        if (!(collectedFee > 0)) {
            revert CustomERROR_No_Collected_Fee();
        }
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
        emit OtherShareHolderChanged(block.timestamp, otherShareholder, _otherShareholder);
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
    function addMainTask(string memory name_, uint joinTime) external nonReentrant returns (bool result){
        // _taskID++;
        require(block.timestamp - lastTaskCreationTime[_msgSender()] > TIME_LIMIT, "You should wait at least 60 seconds before try to create another main task!");
        _mainTasks[_msgSender()].push(Task(_mainTaskCounter.current(), address(_msgSender()), name_, true, true, joinTime));
        emit MainTaskCreated(_mainTaskCounter.current(), address(_msgSender()), name_, true, true, joinTime);
        _mainTaskCounter.increment();

        unchecked {
            taskCount[_msgSender()]++;
        }

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
        uint len;
        assembly { len := extcodesize(attendeeAddress) }
        if (len != 0) {
            revert CustomERROR_Not_A_Wallet_Address();
        }
        Task memory _task = _mainTasks[_msgSender()][mainTaskID];
        // below will be changed
        require(_task.owner != attendeeAddress, "Task owner cannot be an attendee at the same time!");
        require(msg.value >= attendeeAmount.mul(110).div(100), "You don't have enough ETH!");
        require(_task.owner == _msgSender(), "You are not the owner of the main task!");
        require(_task.active, "This main task is already deactivated!");
        require(attendeeAddress != address(0) && attendeeAddress != address(0x0) && attendeeAddress != address(0xdEaD), "Attendee address cannot be zero or dead address!");
        _attendeesMainTask[attendeeAddress].push(Attendee(mainTaskID, attendeeAddress, attendeeAmount, true));
        unchecked {
            collectedFee += attendeeAmount.mul(100).div(1000);
        }
        emit AttendeeAddedToMainTask(mainTaskID, attendeeAddress, attendeeAmount, true);
        return true;
    }
    /* MAIN TASKS */
    
    /* MAIN TASKS - TIME CHECKER */
    function checkIfTimePassed(address address_, uint mainTaskID) internal view returns (bool hasTimePassed) {
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
