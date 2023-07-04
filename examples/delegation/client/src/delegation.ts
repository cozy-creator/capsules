import { beginTxAuth, createDelegationStore, destroyDelegationStore, returnAndShareDelegationStore } from "./txb";
import { baseGasBudget, ownerSigner, ownershipPackageId } from "./config";
import { getCreatedIdsFromResponseWithType, printTxStat, sleep } from "./utils";
import { RawSigner, TransactionBlock } from "@mysten/sui.js";

const storeType = `${ownershipPackageId}::delegation::DelegationStore`;

export async function createAndShareDelegationStore(signer: RawSigner) {
  const txb = new TransactionBlock();
  const [store] = createDelegationStore(txb);

  returnAndShareDelegationStore(txb, store);
  txb.setGasBudget(baseGasBudget);

  const response = await signer.signAndExecuteTransactionBlock({
    transactionBlock: txb,
    options: { showEffects: true },
  });

  printTxStat("create and share delegation store", response);
  await sleep();

  const [storeId] = await getCreatedIdsFromResponseWithType(response, [storeType]);
  return storeId;
}

async function createAndDestroyDelegationStore(signer: RawSigner) {
  const txb = new TransactionBlock();
  const [store] = createDelegationStore(txb);
  const [auth] = beginTxAuth(txb);

  destroyDelegationStore(txb, { store, auth });
  txb.setGasBudget(baseGasBudget);

  const response = await signer.signAndExecuteTransactionBlock({
    transactionBlock: txb,
    options: { showEffects: true },
  });

  printTxStat("create and destroy delegation store", response);
}

// createAndShareDelegationStore(ownerSigner);
// createAndDestroyDelegationStore(ownerSigner);
