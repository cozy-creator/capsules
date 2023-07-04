import { TransactionBlock } from "@mysten/sui.js";
import {
  beginTxAuth,
  claimDelegation,
  claimOrganizationPermissions,
  createCapsuleBaby,
  addPermissionForObjects,
  editCapsuleBabyName,
  grantPermissiontoOrganizationRole,
  returnAndShareCapsuleBaby,
  revokePermissionFromOrganizationRole,
  setOrganizationRoleForAgent,
  removePermissionForObjects,
  addGeneralPermission,
  removeGeneralPermission,
  addPermissionForType,
  removeTypePermission,
} from "./txb";
import { agentSigner, babyPackageId, baseGasBudget, fakeOwnerSigner, ownerSigner } from "./config";

import { getCreatedIdsFromResponseWithType, printTxStat } from "./utils";
import { createAndShareDelegationStore } from "./delegation";

const capsuleBabyType = `${babyPackageId}::capsule_baby::CapsuleBaby`;

interface EditBabyOptions {
  babyId: string;
  newName: string;
}

interface EditBabyWithDelegationOptions extends EditBabyOptions {
  storeId: string;
}

interface EditBabyWithOrgAuthOptions extends EditBabyOptions {
  organizationId: string;
}

async function createAndShareCapsuleBaby(name: string) {
  const txb = new TransactionBlock();
  const [baby] = createCapsuleBaby(txb, name);

  returnAndShareCapsuleBaby(txb, baby);
  txb.setGasBudget(baseGasBudget);

  const response = await ownerSigner.signAndExecuteTransactionBlock({
    transactionBlock: txb,
    options: { showEffects: true },
  });

  printTxStat("create and share baby", response);

  const [babyId] = await getCreatedIdsFromResponseWithType(response, [capsuleBabyType]);
  return babyId;
}

async function editByOwner({ newName, babyId }: EditBabyOptions) {
  const txb = new TransactionBlock();
  const [auth] = beginTxAuth(txb);

  editCapsuleBabyName(txb, { newName, auth, baby: babyId });
  txb.setGasBudget(baseGasBudget);

  const response = await ownerSigner.signAndExecuteTransactionBlock({
    transactionBlock: txb,
    options: {
      showEffects: true,
    },
  });

  printTxStat("Edit baby by owner", response);
}

async function editBabyByAgentWithGeneralPermission({ newName, babyId, storeId }: EditBabyWithDelegationOptions) {
  const permissionType = `${babyPackageId}::capsule_baby::EDITOR`;
  const agent = await agentSigner.getAddress();
  {
    const txb = new TransactionBlock();
    const [auth] = beginTxAuth(txb);

    addGeneralPermission(txb, { permissionType, agent, auth, store: storeId });
    txb.setGasBudget(baseGasBudget);

    await ownerSigner.signAndExecuteTransactionBlock({
      transactionBlock: txb,
      options: { showEffects: true },
    });
  }

  {
    const txb = new TransactionBlock();
    const [auth] = claimDelegation(txb, storeId);
    editCapsuleBabyName(txb, { baby: babyId, auth, newName });
    txb.setGasBudget(baseGasBudget);

    const response = await agentSigner.signAndExecuteTransactionBlock({
      transactionBlock: txb,
      options: { showEffects: true },
    });

    printTxStat("Edit baby with general delegation", response);
  }

  await revokeGeneralPermisssion({ store: storeId, permissionType });
}

async function editBabyByAgentWithObjectPermission({ newName, babyId, storeId }: EditBabyWithDelegationOptions) {
  const permissionType = `${babyPackageId}::capsule_baby::EDITOR`;
  const agent = await agentSigner.getAddress();
  {
    const txb = new TransactionBlock();
    const [auth] = beginTxAuth(txb);

    addPermissionForObjects(txb, { permissionType, agent, ids: [babyId], auth, store: storeId });
    txb.setGasBudget(baseGasBudget);

    await ownerSigner.signAndExecuteTransactionBlock({
      transactionBlock: txb,
      options: { showEffects: true },
    });
  }

  {
    const txb = new TransactionBlock();
    const [auth] = claimDelegation(txb, storeId);
    editCapsuleBabyName(txb, { baby: babyId, auth, newName });
    txb.setGasBudget(baseGasBudget);

    const response = await agentSigner.signAndExecuteTransactionBlock({
      transactionBlock: txb,
      options: { showEffects: true },
    });

    printTxStat("Edit baby with object delegation", response);
  }

  await revokeBabyPermisssion({ store: storeId, permissionType, babyId });
}

async function editByAgentWithInvalidObjectPermission({ newName, babyId, storeId }: EditBabyWithDelegationOptions) {
  const txb = new TransactionBlock();
  const [auth] = claimDelegation(txb, storeId);
  editCapsuleBabyName(txb, { baby: babyId, auth, newName });
  txb.setGasBudget(baseGasBudget);

  const response = await agentSigner.signAndExecuteTransactionBlock({
    transactionBlock: txb,
    options: {
      showEffects: true,
    },
  });

  printTxStat("Edit baby invalid object delegation", response);
}

async function editBabyByAgentWithTypePermission({ newName, babyId, storeId }: EditBabyWithDelegationOptions) {
  const permissionType = `${babyPackageId}::capsule_baby::EDITOR`;
  const agent = await agentSigner.getAddress();
  {
    const txb = new TransactionBlock();
    const [auth] = beginTxAuth(txb);

    addPermissionForType(txb, { objectType: capsuleBabyType, permissionType, agent, auth, store: storeId });
    txb.setGasBudget(baseGasBudget);

    await ownerSigner.signAndExecuteTransactionBlock({
      transactionBlock: txb,
      options: { showEffects: true },
    });
  }

  {
    const txb = new TransactionBlock();
    const [auth] = claimDelegation(txb, storeId);
    editCapsuleBabyName(txb, { baby: babyId, auth, newName });
    txb.setGasBudget(baseGasBudget);

    const response = await agentSigner.signAndExecuteTransactionBlock({
      transactionBlock: txb,
      options: { showEffects: true },
    });

    printTxStat("Edit baby with type delegation", response);
  }

  await revokeTypePermisssion({ store: storeId, permissionType, objectType: capsuleBabyType });
}

async function editBabyByAgentWithFakeOwnerDelegationStore({
  newName,
  babyId,
  storeId,
}: EditBabyWithDelegationOptions) {
  {
    const permissionType = `${babyPackageId}::capsule_baby::EDITOR`;
    const agent = await agentSigner.getAddress();

    const txb = new TransactionBlock();
    const [auth] = beginTxAuth(txb);

    addPermissionForObjects(txb, { permissionType, agent, ids: [babyId], auth, store: storeId });
    txb.setGasBudget(baseGasBudget);

    await fakeOwnerSigner.signAndExecuteTransactionBlock({
      transactionBlock: txb,
      options: { showEffects: true },
    });
  }

  {
    const txb = new TransactionBlock();
    const [auth] = claimDelegation(txb, storeId);
    editCapsuleBabyName(txb, { baby: babyId, auth, newName });
    txb.setGasBudget(baseGasBudget);

    const response = await agentSigner.signAndExecuteTransactionBlock({
      transactionBlock: txb,
      options: { showEffects: true },
    });

    printTxStat("Edit baby with fake owner delegation", response);
  }
}

async function editBabyByOrganizationPermission({ newName, organizationId, babyId }: EditBabyWithOrgAuthOptions) {
  const permissionType = `${babyPackageId}::capsule_baby::EDITOR`;

  const txb = new TransactionBlock();
  const agent = await agentSigner.getAddress();
  const [auth] = beginTxAuth(txb);

  setOrganizationRoleForAgent(txb, { organization: organizationId, role: "Editor", agent, auth });
  grantPermissiontoOrganizationRole(txb, { organization: organizationId, role: "Editor", permissionType, auth });

  txb.setGasBudget(baseGasBudget);

  await ownerSigner.signAndExecuteTransactionBlock({
    transactionBlock: txb,
    options: {
      showEffects: true,
    },
  });

  {
    const txb = new TransactionBlock();
    const [auth] = claimOrganizationPermissions(txb, organizationId);
    editCapsuleBabyName(txb, { baby: babyId, auth, newName });
    txb.setGasBudget(baseGasBudget);

    const response = await agentSigner.signAndExecuteTransactionBlock({
      transactionBlock: txb,
      options: { showEffects: true },
    });

    printTxStat("Edit baby with org auth", response);
  }
}

async function editBabyByOrganizationRevokedPermission({
  newName,
  organizationId,
  babyId,
}: EditBabyWithOrgAuthOptions) {
  const permissionType = `${babyPackageId}::capsule_baby::EDITOR`;

  const txb = new TransactionBlock();
  const [auth] = beginTxAuth(txb);
  const agent = await agentSigner.getAddress();

  setOrganizationRoleForAgent(txb, { organization: organizationId, role: "Editor", agent, auth });
  grantPermissiontoOrganizationRole(txb, { organization: organizationId, role: "Editor", permissionType, auth });
  revokePermissionFromOrganizationRole(txb, { organization: organizationId, role: "Editor", permissionType, auth });
  txb.setGasBudget(baseGasBudget);

  await ownerSigner.signAndExecuteTransactionBlock({
    transactionBlock: txb,
    options: {
      showEffects: true,
    },
  });

  {
    const txb = new TransactionBlock();
    const [auth] = claimOrganizationPermissions(txb, organizationId);
    editCapsuleBabyName(txb, { baby: babyId, auth, newName });
    txb.setGasBudget(baseGasBudget);

    const response = await agentSigner.signAndExecuteTransactionBlock({
      transactionBlock: txb,
      options: { showEffects: true },
    });

    printTxStat("Edit baby with org revoked auth", response);
  }
}

async function revokeBabyPermisssion({
  store,
  babyId,
  permissionType,
}: {
  store: string;
  babyId: string;
  permissionType: string;
}) {
  const agent = await agentSigner.getAddress();

  const txb = new TransactionBlock();
  const [auth] = claimDelegation(txb, store);
  removePermissionForObjects(txb, { ids: [babyId], auth, permissionType, agent, store });
  txb.setGasBudget(baseGasBudget);

  await ownerSigner.signAndExecuteTransactionBlock({
    transactionBlock: txb,
    options: { showEffects: true },
  });
}

async function revokeGeneralPermisssion({ store, permissionType }: { store: string; permissionType: string }) {
  const agent = await agentSigner.getAddress();

  const txb = new TransactionBlock();
  const [auth] = claimDelegation(txb, store);
  removeGeneralPermission(txb, { auth, permissionType, agent, store });
  txb.setGasBudget(baseGasBudget);

  await ownerSigner.signAndExecuteTransactionBlock({
    transactionBlock: txb,
    options: { showEffects: true },
  });
}

async function revokeTypePermisssion({
  store,
  objectType,
  permissionType,
}: {
  store: string;
  objectType: string;
  permissionType: string;
}) {
  const agent = await agentSigner.getAddress();

  const txb = new TransactionBlock();
  const [auth] = claimDelegation(txb, store);
  removeTypePermission(txb, { objectType, auth, permissionType, agent, store });
  txb.setGasBudget(baseGasBudget);

  await ownerSigner.signAndExecuteTransactionBlock({
    transactionBlock: txb,
    options: { showEffects: true },
  });
}

async function main() {
  const babyId = await createAndShareCapsuleBaby("Ayo");

  const storeId = await createAndShareDelegationStore(ownerSigner);
  const organizationId = "0xca27953f81af408a7746a95e1c0f3acffb5c54250c257f4cff6ef8238cf29c6a";

  await editByOwner({ babyId, newName: "Mide" });

  await editBabyByAgentWithGeneralPermission({ babyId, storeId, newName: "Maxine" });

  await editBabyByAgentWithObjectPermission({ babyId, storeId, newName: "Max" });

  await editByAgentWithInvalidObjectPermission({ babyId, storeId, newName: "Bob" });

  await editBabyByAgentWithTypePermission({ babyId, storeId, newName: "Paul" });

  await editBabyByAgentWithFakeOwnerDelegationStore({ babyId, storeId, newName: "Wura" });

  await editBabyByOrganizationPermission({ babyId, organizationId, newName: "Rahman" });

  await editBabyByOrganizationRevokedPermission({ babyId, organizationId, newName: "Kehinde" });
}

main();
