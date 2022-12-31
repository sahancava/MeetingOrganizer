const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('ShareHolder Contract Deployment', function () {
    async function deployTokenFixture() {
        const [owner, addr1] = await ethers.getSigners();
        const Contract = await ethers.getContractFactory('ShareHolder');
        const hardhatContract = await Contract.deploy();
        return { owner, addr1, hardhatContract };
    }
    describe('After deployment init checks', function () {
        it('Should set the right owner', async function () {
            const { hardhatContract, owner } = await loadFixture(deployTokenFixture);
            expect(await hardhatContract.owner()).to.equal(owner.address);
        })
        it('Collected fee amount should equal to zero', async function () {
            const { hardhatContract } = await loadFixture(deployTokenFixture);
            const collectedFee = await hardhatContract.queryCollectedFee();
            expect(await collectedFee).to.equal(Number(ethers.BigNumber.from(0)));
        })
        it('Cannot withdraw since the collected amount is not greater than zero', async function () {
            const { hardhatContract } = await loadFixture(deployTokenFixture);
            await expect(hardhatContract.withdraw()).to.be.rejectedWith('There is no collected fee in the contract!')
        })
    })
})