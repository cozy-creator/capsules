import { MIST_PER_SUI, SUI_CLOCK_OBJECT_ID, SUI_TYPE_ARG, TransactionBlock } from "@mysten/sui.js";
import {
  addRebill,
  cancelRebill,
  create_ as createCoin23_,
  create as createCoin23,
  importFromCoin,
  withdrawWithRebill,
} from "../economy/coin23/functions";
import { Coin23 } from "../economy/coin23/structs";
import { baseGasBudget, merchantSigner, ownerSigner, coinRegistryId } from "./config";
import { begin as beginTxAuth } from "../ownership/tx-authority/functions";
import { runTxb, createdObjects, sleep } from "./utils";

async function main() {
  const coins23: string[] = [];
  const coinTypeArg = SUI_TYPE_ARG;
  const ownerAddress = await ownerSigner.getAddress();
  const merchantAddress = await merchantSigner.getAddress();
  const coinImportAmount = BigInt(0.1 * Number(MIST_PER_SUI));
  const rebillAmount = BigInt(0.01 * Number(MIST_PER_SUI));

  {
    console.log("Create needed coin23's");

    const txb = new TransactionBlock();
    createCoin23_(txb, coinTypeArg, ownerAddress);
    createCoin23_(txb, coinTypeArg, merchantAddress);

    txb.setGasBudget(baseGasBudget);
    const response = await runTxb(txb, ownerSigner);
    const objects = await createdObjects(response);

    coins23.push(...objects[`${Coin23.$typeName}<${coinTypeArg}>`]);
  }

  {
    console.log("Import from coin into customer coin23");

    const txb = new TransactionBlock();
    const [coin] = txb.splitCoins(txb.gas, [txb.pure(coinImportAmount)]);
    importFromCoin(txb, coinTypeArg, { account: coins23[0], coin });

    txb.setGasBudget(baseGasBudget);
    await runTxb(txb, ownerSigner);
  }

  {
    console.log("Add rebill to customer accounts");

    const txb = new TransactionBlock();
    const [auth] = beginTxAuth(txb);

    addRebill(txb, coinTypeArg, {
      auth,
      customer: coins23[0],
      refreshCadence: 3000n,
      maxAmount: rebillAmount,
      registry: coinRegistryId,
      clock: SUI_CLOCK_OBJECT_ID,
      merchantAddr: merchantAddress,
    });

    txb.setGasBudget(baseGasBudget);
    await runTxb(txb, ownerSigner);

    {
      let count = 0;
      const interval = setInterval(async () => {
        if (count == 3) {
          clearInterval(interval);
          return;
        }

        console.log("Withdraw with rebill");

        const txb = new TransactionBlock();
        const [auth] = beginTxAuth(txb);
        withdrawWithRebill(txb, coinTypeArg, {
          auth,
          rebillIndex: 0n,
          amount: rebillAmount,
          customer: coins23[0],
          merchant: coins23[1],
          registry: coinRegistryId,
          clock: SUI_CLOCK_OBJECT_ID,
        });

        txb.setGasBudget(baseGasBudget);
        await runTxb(txb, merchantSigner);

        count++;
      }, 4000);
    }

    await sleep(15000);
  }

  {
    console.log("Withdraw with rebill before cancellation");

    const txb = new TransactionBlock();
    const [auth] = beginTxAuth(txb);

    withdrawWithRebill(txb, coinTypeArg, {
      auth,
      rebillIndex: 0n,
      amount: rebillAmount,
      customer: coins23[0],
      merchant: coins23[1],
      registry: coinRegistryId,
      clock: SUI_CLOCK_OBJECT_ID,
    });

    txb.setGasBudget(baseGasBudget);
    await runTxb(txb, merchantSigner);
  }

  {
    console.log("Cancel rebill by customer");

    const txb = new TransactionBlock();
    const [auth] = beginTxAuth(txb);
    cancelRebill(txb, coinTypeArg, { auth, rebillIndex: 0n, customer: coins23[0], merchantAddr: merchantAddress });

    txb.setGasBudget(baseGasBudget);
    await runTxb(txb, merchantSigner);
  }

  {
    console.log("Withdraw with rebill after cancellation");

    const txb = new TransactionBlock();
    const [auth] = beginTxAuth(txb);

    withdrawWithRebill(txb, coinTypeArg, {
      auth,
      rebillIndex: 0n,
      amount: rebillAmount,
      customer: coins23[0],
      merchant: coins23[1],
      registry: coinRegistryId,
      clock: SUI_CLOCK_OBJECT_ID,
    });

    txb.setGasBudget(baseGasBudget);
    await runTxb(txb, merchantSigner);
  }
}

main();
