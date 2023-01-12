import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract } from 'ethers';
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe('MeetingOrganizer Contract Deployment', function () {
    let hardhatContract: Contract;
    let owner: SignerWithAddress, addr1: SignerWithAddress;

    this.beforeEach(async () => {
        const [_owner, _addr1] = await ethers.getSigners();
        const Contract = await ethers.getContractFactory('MeetingOrganizer');
        hardhatContract = await Contract.deploy();
        owner = _owner;
        addr1 = _addr1;
    })

    before(async () => {
        console.log('\n')
    })

    describe('########## ---> Contract Ownership <--- ###################################', function () {
        
        // --> Below `after` can be commented.
        after(async () => { 
            console.log('\tHardhat Owner: ', await hardhatContract.owner())
            console.log('\tContract Owner: ', owner.address)
            console.log('\n')
        })
        
        it('Should set the right owner', async function () {
            expect(await hardhatContract.owner()).to.equal(owner.address);
        })
    })

    describe('########## ---> Collected Fee and Withdraw Function Testing <--- ##########', function () {

        it('Collected fee amount should equal to zero', async function () {
            const collectedFee = await hardhatContract.queryCollectedFee()
            expect(collectedFee).to.equal(0)
        })
        it('Cannot execute the function since the caller is not the contract owner', async function () {
            await expect(hardhatContract.connect(addr1).queryCollectedFee()).to.be.rejectedWith('Ownable: caller is not the owner')
        })
        it('Cannot withdraw since the collected amount is not greater than zero', async function () {
            await expect(hardhatContract.withdraw()).to.be.rejectedWith('There is no collected fee in the contract!')
        })
        it('Should add a new main task', async function () {
            const taskName = 'Task 0';
            const joinTime = Date.now();
            const tx = await hardhatContract.addMainTask(taskName, joinTime);
            expect((await tx.wait()).events[0].event).to.equal('MainTaskCreated');
            const firstMainTask = await hardhatContract.getSingleMainTask(owner.address, 0);
            expect(firstMainTask.name).to.equal(taskName);
            expect(firstMainTask.id).to.equal(0);
            expect(firstMainTask.isMainTask).to.be.true;
            expect(firstMainTask.active).to.be.true;
            expect(firstMainTask.joinTime).to.equal(joinTime);
            expect(firstMainTask.owner).to.equal(owner.address);
        });
        it('Should retrieve all main tasks', async function () {
            const taskName = 'Task 1';
            const joinTime = Date.now();
            await hardhatContract.addMainTask(taskName, joinTime);
            const tasks = await hardhatContract.getMainTasks(owner.address);
            expect(tasks.length).to.equal(1);
            expect(tasks[0].name).to.equal(taskName);
            expect(tasks[0].id).to.equal(0);
            expect(tasks[0].isMainTask).to.be.true;
            expect(tasks[0].active).to.be.true;
            expect(tasks[0].joinTime).to.equal(joinTime);
            expect(tasks[0].owner).to.equal(owner.address);
        });
        it('Should retrieve a single main task', async function () {
            const taskName = 'Task 2';
            const joinTime = Date.now();
            await hardhatContract.addMainTask(taskName, joinTime);
            const singleTask = await hardhatContract.getSingleMainTask(owner.address, 0);
            expect(singleTask.name).to.equal(taskName);
            expect(singleTask.id).to.equal(0);
            expect(singleTask.isMainTask).to.be.true;
            expect(singleTask.active).to.be.true;
            expect(singleTask.joinTime).to.equal(joinTime);
            expect(singleTask.owner).to.equal(owner.address);
        });
        it('Should retrieve main task owner', async function () {
            const taskName = 'Task 3';
            const joinTime = Date.now();
            await hardhatContract.addMainTask(taskName,joinTime);
            const task = await hardhatContract.getSingleMainTask(owner.address, 0);
            const taskOwner = await hardhatContract.owner();
            expect(task.owner).to.equal(taskOwner);
        });
        it('Should add an attendee to a main task', async function () {
            const taskName = 'Task 4';
            const joinTime = Date.now();
            await hardhatContract.addMainTask(taskName,joinTime);
            const attendeeAddress = addr1.address;
            const attendeeAmount = ethers.utils.parseEther('1');
            await hardhatContract.addAttendee(0, attendeeAddress, attendeeAmount);
            const attendees = await hardhatContract.getMainAttendees(attendeeAddress);
            expect(attendees.length).to.equal(1);
            const attendee = attendees[0];
            expect(attendee.taskID).to.equal(0);
            expect(attendee.address_).to.equal(attendeeAddress);
            expect(attendee.attendeeAmount).to.equal(attendeeAmount);
            expect(attendee.active).to.be.true;
        });
        
    })
})