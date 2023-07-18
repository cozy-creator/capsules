import { SUI_TYPE_ARG, TransactionBlock } from "@mysten/sui.js";
import {
  create as createCoin23,
  create_ as createCoin23_,
  destroyEmpty as destroyEmptyCoin23,
  destroy as destroyCoin23,
  exportToBalance,
  exportToCoin,
  importFromBalance,
  importFromCoin,
  returnAndShare,
  transfer as transferCoin23,
} from "../economy/coin23/functions";
import { Coin23 } from "../economy/coin23/structs";
import { fromBalance, intoBalance } from "../sui/coin/functions";
import { begin as beginTxAuth } from "../ownership/tx-authority/functions";
import { baseGasBudget, coinRegistryId, ownerSigner } from "./config";
import { createdObjects, runTxb } from "./utils";

async function main() {
  const coins23: string[] = [];
  const coinTypeArg = SUI_TYPE_ARG;
  const ownerAddress = await ownerSigner.getAddress();

  {
    console.log("Create first coin23");

    const txb = new TransactionBlock();
    createCoin23_(txb, coinTypeArg, ownerAddress);

    txb.setGasBudget(baseGasBudget);
    const response = await runTxb(txb, ownerSigner);
    const objects = await createdObjects(response);

    coins23.push(...objects[`${Coin23.$typeName}<${SUI_TYPE_ARG}>`]);
  }

  {
    console.log("Create second coin23");

    const txb = new TransactionBlock();
    const [coin23] = createCoin23(txb, SUI_TYPE_ARG);
    returnAndShare(txb, coinTypeArg, { account: coin23, owner: ownerAddress });

    txb.setGasBudget(baseGasBudget);
    const response = await runTxb(txb, ownerSigner);
    const objects = await createdObjects(response);

    coins23.push(...objects[`${Coin23.$typeName}<${SUI_TYPE_ARG}>`]);
  }

  {
    console.log("Import from coin into first coin23");

    const txb = new TransactionBlock();
    const [coin] = txb.splitCoins(txb.gas, [txb.pure(20000000)]);
    importFromCoin(txb, coinTypeArg, { account: coins23[0], coin });

    txb.setGasBudget(baseGasBudget);
    await runTxb(txb, ownerSigner);
  }

  {
    console.log("Import from balance into first coin23");

    const txb = new TransactionBlock();
    const coin = txb.splitCoins(txb.gas, [txb.pure(20000000)]);
    const [balance] = intoBalance(txb, coinTypeArg, coin);
    importFromBalance(txb, coinTypeArg, { account: coins23[0], balance });

    txb.setGasBudget(baseGasBudget);
    await runTxb(txb, ownerSigner);
  }

  {
    console.log("Transfer amount from second coin23 (with insufficient balance) to the first one");

    const txb = new TransactionBlock();
    const [auth] = beginTxAuth(txb);
    transferCoin23(txb, coinTypeArg, {
      amount: 100000n,
      auth,
      from: coins23[1],
      to: coins23[0],
      registry: coinRegistryId,
    });

    txb.setGasBudget(baseGasBudget);
    await runTxb(txb, ownerSigner);
  }

  {
    console.log("Transfer amount from first coin23 to the second one");

    const txb = new TransactionBlock();
    const [auth] = beginTxAuth(txb);
    transferCoin23(txb, coinTypeArg, {
      amount: 100000n,
      auth,
      from: coins23[0],
      to: coins23[1],
      registry: coinRegistryId,
    });

    txb.setGasBudget(baseGasBudget);
    await runTxb(txb, ownerSigner);
  }

  {
    console.log("Export amount from first coin23 to coin");

    const txb = new TransactionBlock();
    const [auth] = beginTxAuth(txb);
    const [coin] = exportToCoin(txb, coinTypeArg, {
      auth,
      amount: 100000n,
      account: coins23[0],
      registry: coinRegistryId,
    });
    txb.transferObjects([coin], txb.pure(ownerAddress));

    txb.setGasBudget(baseGasBudget);
    await runTxb(txb, ownerSigner);
  }

  {
    console.log("Export amount from first coin23 to balance");

    const txb = new TransactionBlock();
    const [auth] = beginTxAuth(txb);

    const [balance] = exportToBalance(txb, coinTypeArg, {
      auth,
      amount: 100000n,
      account: coins23[0],
      registry: coinRegistryId,
    });

    txb.transferObjects([fromBalance(txb, coinTypeArg, balance)], txb.pure(ownerAddress));

    txb.setGasBudget(baseGasBudget);
    await runTxb(txb, ownerSigner);
  }

  {
    console.log("Export more than available amount from first coin23 to coin");

    const txb = new TransactionBlock();
    const [auth] = beginTxAuth(txb);
    const [coin] = exportToCoin(txb, coinTypeArg, {
      auth,
      amount: 1000000000n,
      account: coins23[0],
      registry: coinRegistryId,
    });
    txb.transferObjects([coin], txb.pure(ownerAddress));

    txb.setGasBudget(baseGasBudget);
    await runTxb(txb, ownerSigner);
  }

  {
    console.log("Export more than available amount from first coin23 to balance");

    const txb = new TransactionBlock();
    const [auth] = beginTxAuth(txb);
    const [balance] = exportToBalance(txb, coinTypeArg, {
      auth,
      amount: 1000000000n,
      account: coins23[0],
      registry: coinRegistryId,
    });

    txb.transferObjects([fromBalance(txb, coinTypeArg, balance)], txb.pure(ownerAddress));

    txb.setGasBudget(baseGasBudget);
    await runTxb(txb, ownerSigner);
  }

  {
    console.log("Empty destroy non-empty coin23");

    const txb = new TransactionBlock();
    const [auth] = beginTxAuth(txb);
    const [coin23] = createCoin23(txb, SUI_TYPE_ARG);

    // import some coin
    const [coin] = txb.splitCoins(txb.gas, [txb.pure(20000000)]);
    importFromCoin(txb, coinTypeArg, { account: coin23, coin });

    // destroy coin23
    destroyEmptyCoin23(txb, coinTypeArg, { auth, account: coin23 });

    txb.setGasBudget(baseGasBudget);
    await runTxb(txb, ownerSigner);
  }

  {
    console.log("Empty destroy empty coin23");

    const txb = new TransactionBlock();
    const [auth] = beginTxAuth(txb);
    const [coin23] = createCoin23(txb, SUI_TYPE_ARG);

    // destroy coin23
    destroyEmptyCoin23(txb, coinTypeArg, { auth, account: coin23 });

    txb.setGasBudget(baseGasBudget);
    await runTxb(txb, ownerSigner);
  }

  {
    console.log("Destroy non-empty coin23 and return balance");

    const txb = new TransactionBlock();
    const [auth] = beginTxAuth(txb);
    const [coin23] = createCoin23(txb, SUI_TYPE_ARG);

    // import some coin
    const [coin] = txb.splitCoins(txb.gas, [txb.pure(20000000)]);
    importFromCoin(txb, coinTypeArg, { account: coin23, coin });

    // destroy coin23
    const [balance] = destroyCoin23(txb, coinTypeArg, { auth, account: coin23, registry: coinRegistryId });
    txb.transferObjects([fromBalance(txb, coinTypeArg, balance)], txb.pure(ownerAddress));

    txb.setGasBudget(baseGasBudget);
    await runTxb(txb, ownerSigner);
  }
}

main();
