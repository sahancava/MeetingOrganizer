import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract } from 'ethers';
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe('MeetingOrganizer Contract Deployment', function () {
    let hardhatContract: Contract;
    let _owner: SignerWithAddress;

    this.beforeEach(async () => {
        console.log('\n');
    })
    
    async function deployTokenFixture() {
        const [owner, addr1] = await ethers.getSigners();
        const Contract = await ethers.getContractFactory('MeetingOrganizer');
        hardhatContract = await Contract.deploy();
        _owner = owner;
        return { owner, addr1, hardhatContract, Contract };
    }

    describe('########## ---> Contract Ownership <--- ##########', function () {
        it('Should set the right owner', async function () {
            const { hardhatContract, owner } = await loadFixture(deployTokenFixture);
            expect(await hardhatContract.owner()).to.equal(owner.address);
        })
        after(async () => { 
            console.log('\t\tHardhat Owner: ', await hardhatContract.owner())
            console.log('\t\tContract Owner: ', _owner.address)
        })
    })
    describe('After deployment init checks', function () {
        it('Collected fee amount should equal to zero', async function () {
            const { hardhatContract } = await loadFixture(deployTokenFixture);
            const collectedFee = await hardhatContract.queryCollectedFee();
            console.log('\t\tCollected Amount: ', (await collectedFee).toString())
            expect(await collectedFee).to.equal(Number(ethers.BigNumber.from(0)));
        })
        it('Cannot execute the function since the caller is not the contract owner', async function () {
            const { hardhatContract, owner, addr1 } = await loadFixture(deployTokenFixture);
            console.log('\t\tContract Owner: ', owner.address)
            console.log('\t\tFunction Caller: ', addr1.address)
            await expect(hardhatContract.connect(addr1).queryCollectedFee()).to.be.rejectedWith('Ownable: caller is not the owner');
        })
        it('Cannot withdraw since the collected amount is not greater than zero', async function () {
            const { hardhatContract } = await loadFixture(deployTokenFixture);
            const collectedFee = await hardhatContract.queryCollectedFee();
            console.log('\t\tCollected Amount: ', (await collectedFee).toString())
            await expect(hardhatContract.withdraw()).to.be.rejectedWith('There is no collected fee in the contract!')
        })
    })
})