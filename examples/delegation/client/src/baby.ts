import { TransactionBlock } from "@mysten/sui.js";
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
import { agentSigner, babyPackageId, basGasBudget, ownerSigner, ownershipPackageId, provider } from "./config";

async function createAndEditByOwner() {
  const txb = new TransactionBlock();
  const [baby] = createCapsuleBaby(txb, "SomeR");
  const [store] = createDelegationStore(txb);
  const [auth] = beginTxAuth(txb);

  editCapsuleBabyName(txb, { newName: "Heyyey", auth, baby });
  returnAndShareCapsuleBaby(txb, baby);
  returnAndShareDelegationStore(txb, store);
  txb.setGasBudget(basGasBudget);

  const res = await ownerSigner.signAndExecuteTransactionBlock({ transactionBlock: txb });
  console.log(res);
}

async function createAndEditByAgentWithoutDelegation() {
  const txb = new TransactionBlock();
  const [baby] = createCapsuleBaby(txb, "SomeR");
  const [store] = createDelegationStore(txb);

  returnAndShareCapsuleBaby(txb, baby);
  returnAndShareDelegationStore(txb, store);
  txb.setGasBudget(basGasBudget);

  const result = await ownerSigner.signAndExecuteTransactionBlock({
    transactionBlock: txb,
    options: {
      showEffects: true,
    },
  });

  if (result.effects && result.effects.created) {
    let babyId, storeId;

    for (let i = 0; i < result.effects.created.length; i++) {
      const { reference } = result.effects.created[i];
      const object = await provider.getObject({ id: reference.objectId, options: { showType: true } });

      if (object.data?.type == `${babyPackageId}::capsule_baby::CapsuleBaby`) {
        babyId = object.data.objectId;
      }

      if (object.data?.type == `${ownershipPackageId}::delegation::DelegationStore`) {
        storeId = object.data.objectId;
      }

      if (storeId && babyId) {
        break;
      }
    }

    if (!storeId) {
      throw new Error(`Cannot find newly created DelegationStore`);
    }

    if (!babyId) {
      throw new Error(`Cannot find newly created CapsuleBaby`);
    }

    {
      const txb = new TransactionBlock();
      const [auth] = claimDelegation(txb, storeId);
      editCapsuleBabyName(txb, { baby: babyId, auth, newName: "Hahh" });
      txb.setGasBudget(basGasBudget);

      await agentSigner.signAndExecuteTransactionBlock({ transactionBlock: txb });
    }
  }
}

async function createAndEditByAgent() {
  const txb = new TransactionBlock();
  const [baby] = createCapsuleBaby(txb, "SomeR");
  const [store] = createDelegationStore(txb);

  returnAndShareCapsuleBaby(txb, baby);
  returnAndShareDelegationStore(txb, store);
  txb.setGasBudget(basGasBudget);

  const result = await ownerSigner.signAndExecuteTransactionBlock({
    transactionBlock: txb,
    options: {
      showEffects: true,
    },
  });

  if (result.effects && result.effects.created) {
    let babyId, storeId;

    for (let i = 0; i < result.effects.created.length; i++) {
      const { reference } = result.effects.created[i];
      const object = await provider.getObject({ id: reference.objectId, options: { showType: true } });

      if (object.data?.type == `${babyPackageId}::capsule_baby::CapsuleBaby`) {
        babyId = object.data.objectId;
      }

      if (object.data?.type == `${ownershipPackageId}::delegation::DelegationStore`) {
        storeId = object.data.objectId;
      }

      if (storeId && babyId) {
        break;
      }
    }

    if (!storeId) {
      throw new Error(`Cannot find newly created DelegationStore`);
    }

    if (!babyId) {
      throw new Error(`Cannot find newly created CapsuleBaby`);
    }

    {
      const txb = new TransactionBlock();
      const agent = await agentSigner.getAddress();
      const [auth] = beginTxAuth(txb);

      delegateBaby(txb, { agent, babyId, auth, store: storeId });
      txb.setGasBudget(basGasBudget);

      await ownerSigner.signAndExecuteTransactionBlock({ transactionBlock: txb });
    }

    {
      const txb = new TransactionBlock();
      const [auth] = claimDelegation(txb, storeId);
      editCapsuleBabyName(txb, { baby: babyId, auth, newName: "Hahh" });
      txb.setGasBudget(basGasBudget);

      await agentSigner.signAndExecuteTransactionBlock({ transactionBlock: txb });
    }
  }
}

createAndEditByAgentWithoutDelegation();
