import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BaseProvider } from "ethers/node_modules/@ethersproject/providers";
import { expect } from "chai";
import { BigNumber, Contract } from "ethers";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { ethers } from "hardhat";
import {
  MyToken,
  MyToken__factory,
  Farming,
  Farming__factory,
} from "../src/types";
import uniswapV2ContractData from "../uniswapV2ContractsData.json";

describe("Test farming contract initialization", function () {
  let farmingContract: Farming;

  let tokenLP: MyToken;
  let tokenReward: MyToken;

  let stakeAmount: BigNumber = ethers.utils.parseUnits("1", "18");
  let rewardAmount: BigNumber = ethers.utils.parseUnits("13", "17");

  let owner: SignerWithAddress,
    user1: SignerWithAddress,
    user2: SignerWithAddress,
    users: SignerWithAddress[];

  beforeEach(async () => {
    [owner, user1, user2, ...users] = await ethers.getSigners();

    const TokenFactory = (await ethers.getContractFactory(
      "MyToken"
    )) as MyToken__factory;
    tokenLP = await TokenFactory.deploy("TokenLP", "TLP");
    tokenReward = await TokenFactory.deploy("TokenLP", "TRD");

    const FarmingFactory = (await ethers.getContractFactory(
      "Farming"
    )) as Farming__factory;
    farmingContract = await FarmingFactory.deploy(
      tokenLP.address,
      tokenReward.address
    );

    await tokenLP.approve(farmingContract.address, stakeAmount);
    await tokenReward.approve(farmingContract.address, rewardAmount);
  });

  /*
   * This fucntion test the initialization process of the implemented staking contract
   * Argument list:
   * 1. uint256 _totalAmount – total amount of tokens that can be staked
   * 2. uint256 _percentage – percentage for the staking (for one epoch).
   * NOTE: The boundaries for the percentage are 0 (0%) -> 10000 (100.00%)
   * 3. uint256 _epochDuration – duration of one epoch (in seconds). For convinience, take average values:
   * - 1 month ~ 2,592,000 seconds
   * 4. uint256 _amountOfEpochs – amount of epochs
   * 5. _startTime – in seconds from 1 January 1970. Better to use timestamps
   */
  it.only("should initialize contract with correct parameters", async () => {
    const percentage: number = 10;
    const epochDuration: number = 10;
    const amountOfEpochs: number = 3;
    const rewardToTransfer: BigNumber = stakeAmount
      .mul(percentage)
      .mul(amountOfEpochs)
      .div(10000);

    await farmingContract.initialize(
      stakeAmount,
      10,
      10,
      3,
      await time.latest()
    ); // await time.latest() – time of the latest block
    expect(await tokenReward.balanceOf(farmingContract.address)).to.be.equal(
      rewardToTransfer
    );
  });
});
