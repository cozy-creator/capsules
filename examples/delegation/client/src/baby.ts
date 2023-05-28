import { SuiTransactionBlockResponse, TransactionBlock } from "@mysten/sui.js";
import {
  beginTxAuth,
  claimDelegation,
  claimOrganizationPermissions,
  createCapsuleBaby,
  createDelegationStore,
  delegateBaby,
  editCapsuleBabyName,
  grantPermissiontoOrganizationRole,
  orgditCapsuleBabyName,
  returnAndShareCapsuleBaby,
  returnAndShareDelegationStore,
  setOrganizationRoleForAgent,
} from "./txb";
import {
  agentSigner,
  babyPackageId,
  baseGasBudget,
  fakeOwnerSigner,
  ownerSigner,
  ownershipPackageId,
  provider,
} from "./config";

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
  if (!storeId) throw new Error("Cannot find delegation store in tx response");
  if (!babyId) throw new Error("Cannot capsule baby in tx response");

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
  if (!storeId) throw new Error("Cannot find delegation store in tx response");
  if (!babyId) throw new Error("Cannot capsule baby in tx response");

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

async function createAndEditBabyByAgentWithFakeOwnerDelegation(initialName: string, editName: string) {
  const txb = new TransactionBlock();
  const [baby] = createCapsuleBaby(txb, initialName);

  returnAndShareCapsuleBaby(txb, baby);
  txb.setGasBudget(baseGasBudget);

  const response = await ownerSigner.signAndExecuteTransactionBlock({
    transactionBlock: txb,
    options: {
      showEffects: true,
    },
  });

  const [babyId] = await getBabyIdAndStoreIdfromTxResponse(response);
  if (!babyId) throw new Error("Cannot capsule baby in tx response");

  let storeId;
  {
    const txb = new TransactionBlock();
    const agent = await agentSigner.getAddress();
    const [store] = createDelegationStore(txb);
    const [auth] = beginTxAuth(txb);

    delegateBaby(txb, { agent, babyId, auth, store });
    returnAndShareDelegationStore(txb, store);
    txb.setGasBudget(baseGasBudget);

    const response = await fakeOwnerSigner.signAndExecuteTransactionBlock({
      transactionBlock: txb,
      options: { showEffects: true },
    });
    const [_, s] = await getBabyIdAndStoreIdfromTxResponse(response);

    if (!s) throw new Error("Cannot find delegation store in tx response");
    storeId = s;
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

async function createAndEditBabyByOrganization(orgId: string, initialName: string, editName: string) {
  const txb = new TransactionBlock();
  const agent = await agentSigner.getAddress();

  const [baby] = createCapsuleBaby(txb, initialName);
  const [auth] = beginTxAuth(txb);

  setOrganizationRoleForAgent(txb, { organization: orgId, role: "Editor", agent, auth });
  grantPermissiontoOrganizationRole(txb, {
    organization: orgId,
    role: "Editor",
    permission: `${babyPackageId}::capsule_baby::EDITOR`,
    auth,
  });

  returnAndShareCapsuleBaby(txb, baby);
  txb.setGasBudget(baseGasBudget);

  const response = await ownerSigner.signAndExecuteTransactionBlock({
    transactionBlock: txb,
    options: {
      showEffects: true,
    },
  });

  const [babyId] = await getBabyIdAndStoreIdfromTxResponse(response);
  if (!babyId) throw new Error("Cannot capsule baby in tx response");

  {
    const txb = new TransactionBlock();
    orgditCapsuleBabyName(txb, { baby: babyId, organization: orgId, newName: editName });
    txb.setGasBudget(baseGasBudget);

    const response = await agentSigner.signAndExecuteTransactionBlock({
      transactionBlock: txb,
    });

    console.log(response);
  }
}

// createAndShareCapsuleBaby("Ayo");
// createAndEditByOwner("Ayo", "Mide");
// createAndEditByAgentWithoutDelegation("Ayo", "Max");
// createAndEditBabyByAgentWithDelegation("Barb", "Ayo");
// createAndEditBabyByAgentWithFakeOwnerDelegation("Barb", "Ayo");
// createAndEditBabyByOrganization("0x7e12ac3390139506742f89ab4c9faa71a04284f561f75b0ee5f73192aecb9cce", "Barb", "Bayo");
