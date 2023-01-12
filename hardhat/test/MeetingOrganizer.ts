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
            await hardhatContract.addMainTask('Task 1', Date.now());
            const attendeeAmount = ethers.utils.parseEther('1');
            const tx = await hardhatContract.addAttendeeToMainTask(0, addr1.address, attendeeAmount, {value: attendeeAmount.mul(110).div(100)});
            const receipt = await tx.wait();
            expect(receipt.events[0].event).to.equal('AttendeeAddedToMainTask');
            expect(receipt.events[0].args.taskID.eq(0)).to.be.true;
            expect(receipt.events[0].args.address_).to.equal(addr1.address);
            expect(receipt.events[0].args.attendeeAmount).to.equal(attendeeAmount);
            const attendees = await hardhatContract.getMainAttendees(addr1.address);
            expect(attendees.length).to.equal(1);
            expect(attendees[0].taskID).to.equal(receipt.events[0].args.taskID);
            expect(attendees[0].address_).to.equal(addr1.address);
            expect(attendees[0].attendeeAmount).to.equal(receipt.events[0].args.attendeeAmount);
            expect(attendees[0].active).to.be.true;
        });
        
    })
})