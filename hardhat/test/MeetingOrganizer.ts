import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract } from 'ethers';
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe('MeetingOrganizer Contract Deployment', function () {
    let hardhatContract: Contract;
    let owner: SignerWithAddress, addr1: SignerWithAddress;
    let collectedFee: Number;
    let counter: number = 0;

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
        
        // --> Below `after` can be uncommented.
        // after(async () => { 
        //     console.log('\t\tHardhat Owner: ', await hardhatContract.owner())
        //     console.log('\t\tContract Owner: ', owner.address)
        //     console.log('\n')
        // })
        
        it('Should set the right owner', async function () {
            expect(await hardhatContract.owner()).to.equal(owner.address);
        })
    })

    describe('########## ---> Collected Fee and Withdraw Function Testing <--- ##########', function () {

        // --> Below `afterEach` and `afterAll` can be commented
        // this.afterEach(async () => {
        //     counter++;
        //     switch (counter) {
        //         case 1:
        //             console.log('\t\tCollected Amount: ', collectedFee.toString())
        //             break;
        //         case 2:
        //             console.log('\t\tContract Owner: ', owner.address)
        //             console.log('\t\tFunction Caller: ', addr1.address)
        //             break;
        //         case 3:
        //             console.log('\t\tCollected Amount: ', collectedFee.toString())
        //             break;
        //     }
        // })
        // this.afterAll(async () => {
        //     counter = 0;
        // })

        it('Collected fee amount should equal to zero', async function () {
            collectedFee = await hardhatContract.queryCollectedFee()
            expect(collectedFee).to.equal(Number(ethers.BigNumber.from(0)))
        })
        it('Cannot execute the function since the caller is not the contract owner', async function () {
            await expect(hardhatContract.connect(addr1).queryCollectedFee()).to.be.rejectedWith('Ownable: caller is not the owner')
        })
        it('Cannot withdraw since the collected amount is not greater than zero', async function () {
            collectedFee = await hardhatContract.queryCollectedFee()
            await expect(hardhatContract.withdraw()).to.be.rejectedWith('There is no collected fee in the contract!')
        })
    })
})