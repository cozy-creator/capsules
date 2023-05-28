import { SuiTransactionBlockResponse, TransactionBlock } from "@mysten/sui.js";
import {
  beginTxAuth,
  claimDelegation,
  createCapsuleBaby,
  createDelegationStore,
  delegateBaby,
  editCapsuleBabyName,
  returnAndShareCapsuleBaby,
  returnAndShareDelegationStore,
} from "./txb";
import { agentSigner, babyPackageId, baseGasBudget, ownerSigner, ownershipPackageId, provider } from "./config";

async function getBabyIdAndStoreIdfromTxResponse(response: SuiTransactionBlockResponse) {
  if (response.effects && response.effects.created) {
    let babyId, storeId;

    for (let i = 0; i < response.effects.created.length; i++) {
      const { reference } = response.effects.created[i];
      const object = await provider.getObject({ id: reference.objectId, options: { showType: true } });

      if (object.data?.type == `${babyPackageId}::capsule_baby::CapsuleBaby`) {
        babyId = object.data.objectId;
      }

      if (object.data?.type == `${ownershipPackageId}::delegation::DelegationStore`) {
        storeId = object.data.objectId;
      }

      if (storeId && babyId) break;
    }

    if (!storeId) throw new Error("Cannot find delegation store in tx response");
    if (!babyId) throw new Error("Cannot capsule baby in tx response");

    return [babyId, storeId];
  }

  return [];
}

async function createAndShareCapsuleBaby(name: string) {
  const txb = new TransactionBlock();
  const [baby] = createCapsuleBaby(txb, name);

  returnAndShareCapsuleBaby(txb, baby);
  txb.setGasBudget(baseGasBudget);

  const response = await ownerSigner.signAndExecuteTransactionBlock({
    transactionBlock: txb,
  });

  console.log(response);
}

async function createAndEditByOwner(initialName: string, editName: string) {
  const txb = new TransactionBlock();
  const [baby] = createCapsuleBaby(txb, initialName);
  const [store] = createDelegationStore(txb);
  const [auth] = beginTxAuth(txb);

  editCapsuleBabyName(txb, { newName: editName, auth, baby });
  returnAndShareCapsuleBaby(txb, baby);
  returnAndShareDelegationStore(txb, store);
  txb.setGasBudget(baseGasBudget);

  const response = await ownerSigner.signAndExecuteTransactionBlock({ transactionBlock: txb });
  console.log(response);
}

async function createAndEditByAgentWithoutDelegation(initialName: string, editName: string) {
  const txb = new TransactionBlock();
  const [baby] = createCapsuleBaby(txb, initialName);
  const [store] = createDelegationStore(txb);

  returnAndShareCapsuleBaby(txb, baby);
  returnAndShareDelegationStore(txb, store);
  txb.setGasBudget(baseGasBudget);

  const response = await ownerSigner.signAndExecuteTransactionBlock({
    transactionBlock: txb,
    options: {
      showEffects: true,
    },
  });

  const [babyId, storeId] = await getBabyIdAndStoreIdfromTxResponse(response);

  {
    const txb = new TransactionBlock();
    const [auth] = claimDelegation(txb, storeId);
    editCapsuleBabyName(txb, { baby: babyId, auth, newName: editName });
    txb.setGasBudget(baseGasBudget);

    const response = await agentSigner.signAndExecuteTransactionBlock({
      transactionBlock: txb,
      options: {
        showEffects: true,
      },
    });

    if (response.effects?.status) {
      console.log(`\nError: ${response.effects.status.error}`);
    }
  }
}

async function createAndEditBabyByAgentWithDelegation(initialName: string, editName: string) {
  const txb = new TransactionBlock();
  const [baby] = createCapsuleBaby(txb, initialName);
  const [store] = createDelegationStore(txb);

  returnAndShareCapsuleBaby(txb, baby);
  returnAndShareDelegationStore(txb, store);
  txb.setGasBudget(baseGasBudget);

  const response = await ownerSigner.signAndExecuteTransactionBlock({
    transactionBlock: txb,
    options: {
      showEffects: true,
    },
  });

  const [babyId, storeId] = await getBabyIdAndStoreIdfromTxResponse(response);

  {
    const txb = new TransactionBlock();
    const agent = await agentSigner.getAddress();
    const [auth] = beginTxAuth(txb);

    delegateBaby(txb, { agent, babyId, auth, store: storeId });
    txb.setGasBudget(baseGasBudget);

    await ownerSigner.signAndExecuteTransactionBlock({ transactionBlock: txb });
  }

  {
    const txb = new TransactionBlock();
    const [auth] = claimDelegation(txb, storeId);
    editCapsuleBabyName(txb, { baby: babyId, auth, newName: editName });
    txb.setGasBudget(baseGasBudget);

    const response = await agentSigner.signAndExecuteTransactionBlock({
      transactionBlock: txb,
    });

    console.log(response);
  }
}

// createAndShareCapsuleBaby("Ayo");
// createAndEditByOwner("Ayo", "Mide");
// createAndEditBabyByAgentWithDelegation("Barb", "Ayo");
// createAndEditByAgentWithoutDelegation("Ayo", "Max");
