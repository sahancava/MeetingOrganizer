// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract MeetingOrganizerAbstract {
    function addMainTask(string memory name_, uint joinTime) external virtual returns (bool);
}

contract MeetingOrganizer is Ownable, MeetingOrganizerAbstract {

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

    mapping(address => Task[]) private _mainTasks;
    mapping(uint => mapping(address => Task[])) private _subTasks;
    mapping(address => Attendee[]) private _attendeesMainTask;
    mapping(address => Attendee[]) private _attendeesSubTask;
    mapping(address => uint256) balances;

    mapping(address => uint) public taskCount;
    mapping(address => uint) public lastTaskCreationTime;

    uint public constant TIME_LIMIT = 60;

    /* MODIFIERS */
    bool internal locked;
    modifier noReentrant() {
        require(!locked, "No re-entrancy!");
        locked = true;
        _;
        locked = false;
    }
    /* MODIFIERS */

    /* EVENTS */
    event MainTaskCreated(
        uint id,
        address owner,
        string name,
        bool isMainTask,
        bool active,
        uint joinTime
    );

    event Received(uint256 amount);
    event MainTaskDeactivated(uint id, uint256 timestamp);
    event AttendeeAddedToMainTask(uint taskID, address address_, uint256 attendeeAmount, bool active);
    event WithdrawedAll(uint256 amount, uint256 time);
    /* EVENTS */

    /* WITHDRAW */
    uint256 private collectedFee;
    function queryCollectedFee() public view onlyOwner returns (uint256) {
        return collectedFee;
    }
    function withdraw() public onlyOwner noReentrant() returns (bool) {
        require(collectedFee > 0, "There is no collected fee in the contract!");
        (bool success, ) = address(msg.sender).call{ value: collectedFee }("");
        require(success, "Transfer failed!");
        emit WithdrawedAll(collectedFee, block.timestamp);
        collectedFee = 0;
        return true;
    }
    /* WITHDRAW */

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
    function addMainTask(string memory name_, uint joinTime) external override noReentrant() returns (bool result){
        // _taskID++;
        require(block.timestamp - lastTaskCreationTime[msg.sender] > TIME_LIMIT, "You should wait at least 60 seconds before try to create another main task!");
        _mainTasks[msg.sender].push(Task(_mainTaskCounter.current(), address(msg.sender), name_, true, true, joinTime));
        emit MainTaskCreated(_mainTaskCounter.current(), address(msg.sender), name_, true, true, joinTime);
        _mainTaskCounter.increment();
        taskCount[msg.sender]++;
        lastTaskCreationTime[msg.sender] = block.timestamp;
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
    function deactivateTheMainTask(uint mainTaskID) public noReentrant() returns (bool) {
        Task storage _task = _mainTasks[msg.sender][mainTaskID];
        require(_task.owner == msg.sender, "You are not the owner of the main task!");
        require(_task.active, "This main task is already deactivated!");
        _task.active = false;
        emit MainTaskDeactivated(mainTaskID, block.timestamp);
        return true;
    }
    function addAttendeeToMainTask(uint mainTaskID, address attendeeAddress, uint256 attendeeAmount) public noReentrant() payable returns (bool) {
        Task storage _task = _mainTasks[msg.sender][mainTaskID];
        // below will be changed
        require(_task.owner != attendeeAddress, "Task owner cannot be a attendee at the same time!");
        require(msg.value >= attendeeAmount.mul(110).div(100), "You don't have enough ETH!");
        require(_task.owner == msg.sender, "You are not the owner of the main task!");
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