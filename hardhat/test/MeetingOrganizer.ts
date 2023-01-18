import { assert, expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract } from 'ethers';
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe('MeetingOrganizer Contract Deployment', function () {
    let hardhatContract: Contract;
    let owner: SignerWithAddress, addr1: SignerWithAddress;

    this.beforeEach(async () => {
        const [_owner, _addr1] = await ethers.getSigners();
        const Contract = await ethers.getContractFactory('MeetingOrganizer');
        hardhatContract = await Contract.deploy('0x0000000000000000000000000000000000000000');
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
            await hardhatContract.addMainTask(taskName, joinTime);
            const task = await hardhatContract.getSingleMainTask(owner.address, 0);
            const taskOwner = await hardhatContract.owner();
            expect(task.owner).to.equal(taskOwner);
        });
        it('Should add an attendee to a main task', async function () {
            await hardhatContract.addMainTask('Task 4', Date.now());
            const attendeeAmount = ethers.utils.parseEther('1');
            let task = await hardhatContract.getSingleMainTask(owner.address, 0);
            expect(task.active).to.be.true;
            await expect(hardhatContract.addAttendeeToMainTask(0, owner.address, attendeeAmount, {value: attendeeAmount.mul(110).div(100)})).to.be.rejectedWith("Task owner cannot be a attendee at the same time!");
            await expect(hardhatContract.addAttendeeToMainTask(0, addr1.address, attendeeAmount, {value: attendeeAmount.mul(90).div(100)})).to.be.rejectedWith("You don't have enough ETH!");
            await expect(hardhatContract.addAttendeeToMainTask(0, '0x0000000000000000000000000000000000000000', attendeeAmount, {value: attendeeAmount.mul(110).div(100)})).to.be.rejectedWith('Attendee address cannot be zero or dead address!');
            await expect(hardhatContract.addAttendeeToMainTask(0, '0x0', attendeeAmount, {value: attendeeAmount.mul(110).div(100)})).to.be.rejectedWith('invalid address');
            await expect(hardhatContract.addAttendeeToMainTask(0, '0xdEaD', attendeeAmount, {value: attendeeAmount.mul(110).div(100)})).to.be.rejectedWith('invalid address');
            await hardhatContract.deactivateTheMainTask(0);
            task = await hardhatContract.getSingleMainTask(owner.address, 0);
            expect(task.active).to.be.false;
            let task2 = await hardhatContract.getSingleMainTask(owner.address, 0);
            expect(task2.active).to.be.false;
            await expect(hardhatContract.addAttendeeToMainTask(0, addr1.address, attendeeAmount, {value: attendeeAmount.mul(110).div(100)})).to.be.rejectedWith("This main task is already deactivated!");
        });
    })

    // I SWEAR ON MY HONOR THAT I WILL GET THIS WORKING ASAP.
    describe('XXXX', function () {
        it('Should deactivate a main task', async function () {
            // Create a main task
            const taskName = 'Task 4';
            const joinTime = Date.now();
            await hardhatContract.addMainTask(taskName, joinTime);
            let task = await hardhatContract.getSingleMainTask(owner.address, 0);
            expect(task.active).to.equal(true);
            await hardhatContract.connect(addr1).deactivateTheMainTask(1);
            // try {
            //     const transaction = await hardhatContract.connect(addr1).deactivateTheMainTask(0);
            //     console.log('transaction: ', transaction)
            //     assert(false, "Expected to throw error, because addr1 is not the owner of the task");
            // } catch (error:any ) {
            //     console.log('error: ', error)
            //     expect(error.message).to.include("You are not the owner of the main task!");
            // }
            // expect(hardhatContract.connect(addr1).deactivateTheMainTask(0)).to.be.rejectedWith('You are not the owner of the main task!');
            // await expect(hardhatContract.connect(addr1).deactivateTheMainTask(1)).to.be.rejectedWith('You are not the owner of the main task!');
            // expect(await hardhatContract.owner()).to.equal(owner.address);

            // Deactivate the main task
            // const tx = await hardhatContract.deactivateTheMainTask(0);
            // expect((await tx.wait()).events[0].event).to.equal('MainTaskDeactivated');
            // task = await hardhatContract.getSingleMainTask(owner.address, 0);
            // expect(task.active).to.equal(false);
        })
    })
})