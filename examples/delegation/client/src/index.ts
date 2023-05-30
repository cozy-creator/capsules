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

  printTxStat("Edit baby invalid delegation auth", response);
}

async function editBabyByAgentWithObjectPermission({ newName, babyId, storeId }: EditBabyWithDelegationOptions) {
  {
    const permissionType = `${babyPackageId}::capsule_baby::EDITOR`;
    const agent = await agentSigner.getAddress();

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

    printTxStat("Edit baby with delegation", response);
  }
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

async function main() {
  const organizationId = "0x531cce643ec633179370feac197503e708b9d6ee17cd25b4259a6f0a95fbd598";
  const babyId = await createAndShareCapsuleBaby("Ayo");
  const storeId = await createAndShareDelegationStore(ownerSigner);

  await editByOwner({ babyId, newName: "Mide" });
  await editBabyByAgentWithObjectPermission({ babyId, storeId, newName: "Max" });
  await editByAgentWithInvalidObjectPermission({ babyId, storeId, newName: "Bob" });
  await editBabyByAgentWithFakeOwnerDelegationStore({ babyId, storeId, newName: "Wura" });
  await editBabyByOrganizationPermission({ babyId, organizationId, newName: "Rahman" });
  await editBabyByOrganizationRevokedPermission({ babyId, organizationId, newName: "Paul" });
}

main();
