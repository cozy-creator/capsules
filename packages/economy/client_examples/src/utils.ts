import {
  MIST_PER_SUI,
  RawSigner,
  SuiTransactionBlockResponse,
  TransactionBlock,
} from "@mysten/sui.js";
import { provider } from "./config";

export async function createdObjects(txb: SuiTransactionBlockResponse) {
  if (!txb.effects?.created) throw new Error("");

  const objects: { [key: string]: string[] } = {};

  const ids = txb.effects.created.map((obj) => obj.reference.objectId);
  const multiObjects = await provider.multiGetObjects({
    ids,
    options: { showType: true },
  });

  for (let i = 0; i < multiObjects.length; i++) {
    const object = multiObjects[i];
    if (!object.data?.type) throw new Error("Object type not found");

    if (objects[object.data.type]) {
      objects[object.data.type] = [
        ...objects[object.data.type],
        object.data.objectId,
      ];
    } else {
      objects[object.data.type] = [object.data.objectId];
    }
  }

  return objects;
}

export async function runTxb(txb: TransactionBlock, signer: RawSigner) {
  const response = await signer.signAndExecuteTransactionBlock({
    transactionBlock: txb,
    options: { showEffects: true },
    requestType: "WaitForLocalExecution",
  });

  const {
    digest,
    effects: {
      status,
      gasUsed: { storageCost = 0, computationCost = 0, storageRebate = 0 } = {},
    } = {},
  } = response;

  console.log(
    {
      digest,
      error: status?.error,
      status: status?.status,
      totalGasUsed: `${
        Number(
          Number(computationCost) + Number(storageCost) - Number(storageRebate),
        ) / Number(MIST_PER_SUI)
      }`,
    },
    "\n",
  );

  return response;
}

export function sleep(ms = 3000) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
