import { task } from "hardhat/config";
import { BigNumber, ContractTransaction, ContractReceipt } from "ethers";
import { ethers } from "ethers";
import { contractAddress } from "../hardhat.config";
import { Address } from "cluster";

async function getLastBlockTimestamp(): Promise<BigNumber> {
  const provider = ethers.providers.getDefaultProvider();
  const blockNumber: number = await provider.getBlockNumber();
  const block: any = await provider.getBlock(blockNumber);
  const timestamp: BigNumber = block.timestamp;
  return timestamp;
}

task(
  "deposit",
  "Makes deposit to the farming contract \
   and transfers LP tokens to the contract for staking. \
   Emits event after successful deposit"
)
  .addParam("depositAmount", "Amount of tokens to stake")
  .setAction(async ({ depositAmount }, { ethers }) => {
    const Contract = await ethers.getContractFactory("Farming");
    const farmingContract = Contract.attach(contractAddress!);
    console.log(await getLastBlockTimestamp());

    const farmingTx: ContractTransaction = await farmingContract.deposit(
      depositAmount
    );
    const farmingReceipt: ContractReceipt = await farmingTx.wait();

    const event = farmingReceipt.events?.find(
      (event) => event.event === "Deposited"
    );
    const addr: Address = event?.args!["addr"];
    const amount: BigNumber = event?.args!["amount"];
    console.log("Successfully deposited tokens for staking");
    console.log(`Address of the holder: ${addr}`);
    console.log(`Deposited amount: ${amount}`);
  });
