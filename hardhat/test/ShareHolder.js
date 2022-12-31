const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('ShareHolder Contract Deployment', function () {
    async function deployTokenFixture() {
        const [owner, addr1] = await ethers.getSigners();
        const Contract = await ethers.getContractFactory('ShareHolder');
        const hardhatContract = await Contract.deploy();
        return { owner, addr1, hardhatContract, Contract };
    }
    describe('After deployment init checks', function () {
        it('Should set the right owner', async function () {
            const { hardhatContract, owner } = await loadFixture(deployTokenFixture);
            console.log('\n\t\tHardhat Owner: ', await hardhatContract.owner())
            console.log('\t\tContract Owner: ', owner.address)
            expect(await hardhatContract.owner()).to.equal(owner.address);
        })
        it('Collected fee amount should equal to zero', async function () {
            const { hardhatContract } = await loadFixture(deployTokenFixture);
            const collectedFee = await hardhatContract.queryCollectedFee();
            console.log('\n\t\tCollected Amount: ', (await collectedFee).toString())
            expect(await collectedFee).to.equal(Number(ethers.BigNumber.from(0)));
        })
        it('Cannot execute the function since the caller is not the contract owner', async function () {
            const { hardhatContract, owner, addr1 } = await loadFixture(deployTokenFixture);
            console.log('\n\t\tContract Owner: ', owner.address)
            console.log('\t\tFunction Caller: ', addr1.address)
            await expect(hardhatContract.connect(addr1).queryCollectedFee()).to.be.rejectedWith('Ownable: caller is not the owner');
        })
        it('Cannot withdraw since the collected amount is not greater than zero', async function () {
            const { hardhatContract } = await loadFixture(deployTokenFixture);
            const collectedFee = await hardhatContract.queryCollectedFee();
            console.log('\n\t\tCollected Amount: ', (await collectedFee).toString())
            await expect(hardhatContract.withdraw()).to.be.rejectedWith('There is no collected fee in the contract!')
        })
    })
})