import { MIST_PER_SUI, SUI_CLOCK_OBJECT_ID, SUI_TYPE_ARG, TransactionBlock } from "@mysten/sui.js";
import {
  addRebill,
  cancelRebill,
  create_ as createCoin23_,
  create as createCoin23,
  importFromCoin,
  withdrawWithRebill,
  addHold,
  releaseHeldFunds,
  withdrawFromHeldFunds,
  importFromBalance,
} from "../economy/coin23/functions";
import { Coin23 } from "../economy/coin23/structs";
import { baseGasBudget, merchantSigner, ownerSigner, coinRegistryId } from "./config";
import { begin as beginTxAuth } from "../ownership/tx-authority/functions";
import { runTxb, createdObjects, sleep } from "./utils";
import { intoBalance } from "../sui/coin/functions";

async function main() {
  const coins23: string[] = [];
  const coinTypeArg = SUI_TYPE_ARG;
  const ownerAddress = await ownerSigner.getAddress();
  const merchantAddress = await merchantSigner.getAddress();
  const coinImportAmount = BigInt(0.1 * Number(MIST_PER_SUI));
  const holdAmount = BigInt(0.01 * Number(MIST_PER_SUI));
  const holdDuration = 5000n;

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
    console.log("Import from balance into first coin23");

    const txb = new TransactionBlock();
    const coin = txb.splitCoins(txb.gas, [txb.pure(coinImportAmount)]);
    const [balance] = intoBalance(txb, coinTypeArg, coin);
    importFromBalance(txb, coinTypeArg, { account: coins23[0], balance });

    txb.setGasBudget(baseGasBudget);
    await runTxb(txb, ownerSigner);
  }

  {
    console.log("Hold customer's coin23 balance");

    const txb = new TransactionBlock();
    const [auth] = beginTxAuth(txb);

    addHold(txb, coinTypeArg, {
      auth,
      amount: holdAmount,
      customer: coins23[0],
      registry: coinRegistryId,
      durationMs: holdDuration,
      clock: SUI_CLOCK_OBJECT_ID,
      merchantAddr: merchantAddress,
    });

    txb.setGasBudget(baseGasBudget);
    await runTxb(txb, ownerSigner);
    await sleep();
  }

  {
    console.log("Withdraw from customer's coin23 held balance");

    const txb = new TransactionBlock();
    const [auth] = beginTxAuth(txb);

    withdrawFromHeldFunds(txb, coinTypeArg, {
      auth,
      amount: 80000n,
      customer: coins23[0],
      merchant: coins23[1],
      registry: coinRegistryId,
      clock: SUI_CLOCK_OBJECT_ID,
    });

    txb.setGasBudget(baseGasBudget);
    await runTxb(txb, merchantSigner);
  }

  {
    await sleep();
    console.log("Withdraw from customer's coin23 held balance after hold expires");

    const txb = new TransactionBlock();
    const [auth] = beginTxAuth(txb);

    withdrawFromHeldFunds(txb, coinTypeArg, {
      auth,
      amount: 80000n,
      customer: coins23[0],
      merchant: coins23[1],
      registry: coinRegistryId,
      clock: SUI_CLOCK_OBJECT_ID,
    });

    txb.setGasBudget(baseGasBudget);
    await runTxb(txb, merchantSigner);
  }

  {
    console.log("Release customer's coin23 held balance");

    const txb = new TransactionBlock();
    const [auth] = beginTxAuth(txb);

    releaseHeldFunds(txb, coinTypeArg, {
      auth,
      customer: coins23[0],
      merchantAddr: merchantAddress,
    });

    txb.setGasBudget(baseGasBudget);
    await runTxb(txb, merchantSigner);
  }
}

main();
