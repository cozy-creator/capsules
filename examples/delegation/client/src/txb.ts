import { TransactionArgument, TransactionBlock } from "@mysten/sui.js";
import { babyPackageId, ownerKeypair, ownerSigner, ownershipPackageId } from "./config";

interface EditBabyNameOptions {
  baby: TransactionArgument | string;
  auth: TransactionArgument;
  newName: string;
}

export interface GeneralPermissionOptions {
  store: TransactionArgument | string;
  auth: TransactionArgument;
  permissionType: string;
  agent: string;
}

export interface ObjectPermissionOptions {
  store: TransactionArgument | string;
  auth: TransactionArgument;
  permissionType: string;
  ids: string[];
  agent: string;
}

export interface TypePermissionOptions {
  store: TransactionArgument | string;
  auth: TransactionArgument;
  permissionType: string;
  objectType: string;
  agent: string;
}

interface AddOrganizationPackageOptions {
  receipt: string;
  auth: TransactionArgument;
  organization: TransactionArgument | string;
}

interface DestroyOrganizationOptions {
  auth: TransactionArgument;
  organization: TransactionArgument | string;
}

interface RemoveOrganizationPackageOptions {
  packageId: string;
  auth: TransactionArgument;
  organization: TransactionArgument | string;
}

interface OrganizationEndorsementOptions {
  address: string;
  auth: TransactionArgument;
  organization: TransactionArgument | string;
}

interface SetOrganizationRoleForAgentOptions {
  agent: string;
  role: string;
  auth: TransactionArgument;
  organization: TransactionArgument | string;
}

interface OrganizationPermissionRoleOptions {
  role: string;
  permissionType: string;
  auth: TransactionArgument;
  organization: TransactionArgument | string;
}

interface DestroyDelegationStoreOptions {
  store: TransactionArgument | string;
  auth: TransactionArgument;
}

export function createDelegationStore(txb: TransactionBlock) {
  return txb.moveCall({
    arguments: [],
    typeArguments: [],
    target: `${ownershipPackageId}::delegation::create`,
  });
}

export function destroyDelegationStore(txb: TransactionBlock, { store, auth }: DestroyDelegationStoreOptions) {
  return txb.moveCall({
    typeArguments: [],
    target: `${ownershipPackageId}::delegation::destroy`,
    arguments: [typeof store == "string" ? txb.object(store) : store, auth],
  });
}
export function returnAndShareDelegationStore(txb: TransactionBlock, store: TransactionArgument) {
  return txb.moveCall({
    typeArguments: [],
    target: `${ownershipPackageId}::delegation::return_and_share`,
    arguments: [store],
  });
}

export function beginTxAuth(txb: TransactionBlock) {
  return txb.moveCall({
    arguments: [],
    typeArguments: [],
    target: `${ownershipPackageId}::tx_authority::begin`,
  });
}

export function claimDelegation(txb: TransactionBlock, store: TransactionArgument | string) {
  return txb.moveCall({
    typeArguments: [],
    target: `${ownershipPackageId}::delegation::claim_delegation`,
    arguments: [typeof store == "string" ? txb.object(store) : store],
  });
}

export function addGeneralPermission(
  txb: TransactionBlock,
  { permissionType, auth, store, agent }: GeneralPermissionOptions
) {
  return txb.moveCall({
    typeArguments: [permissionType],
    target: `${ownershipPackageId}::delegation::add_permission`,
    arguments: [typeof store == "string" ? txb.object(store) : store, txb.pure(agent), auth],
  });
}

export function addPermissionForObjects(
  txb: TransactionBlock,
  { permissionType, auth, store, agent, ids }: ObjectPermissionOptions
) {
  return txb.moveCall({
    typeArguments: [permissionType],
    target: `${ownershipPackageId}::delegation::add_permission_for_objects`,
    arguments: [typeof store == "string" ? txb.object(store) : store, txb.pure(agent), txb.pure(ids), auth],
  });
}

export function addPermissionForType(
  txb: TransactionBlock,
  { objectType, permissionType, auth, store, agent }: TypePermissionOptions
) {
  return txb.moveCall({
    typeArguments: [objectType, permissionType],
    target: `${ownershipPackageId}::delegation::add_permission_for_type`,
    arguments: [typeof store == "string" ? txb.object(store) : store, txb.pure(agent), auth],
  });
}

export function removePermissionForObjects(
  txb: TransactionBlock,
  { permissionType, auth, store, agent, ids }: ObjectPermissionOptions
) {
  return txb.moveCall({
    typeArguments: [permissionType],
    target: `${ownershipPackageId}::delegation::remove_permission_for_objects_from_agent`,
    arguments: [typeof store == "string" ? txb.object(store) : store, txb.pure(agent), txb.pure(ids), auth],
  });
}

export function removeGeneralPermission(
  txb: TransactionBlock,
  { permissionType, auth, store, agent }: GeneralPermissionOptions
) {
  return txb.moveCall({
    typeArguments: [permissionType],
    target: `${ownershipPackageId}::delegation::remove_general_permission_from_agent`,
    arguments: [typeof store == "string" ? txb.object(store) : store, txb.pure(agent), auth],
  });
}

export function removeTypePermission(
  txb: TransactionBlock,
  { objectType, permissionType, auth, store, agent }: TypePermissionOptions
) {
  return txb.moveCall({
    typeArguments: [objectType, permissionType],
    target: `${ownershipPackageId}::delegation::remove_permission_for_type_from_agent`,
    arguments: [typeof store == "string" ? txb.object(store) : store, txb.pure(agent), auth],
  });
}

export function createCapsuleBaby(txb: TransactionBlock, name: string) {
  return txb.moveCall({
    arguments: [txb.pure(name)],
    target: `${babyPackageId}::capsule_baby::create_baby`,
    typeArguments: [],
  });
}

export function returnAndShareCapsuleBaby(txb: TransactionBlock, baby: TransactionArgument) {
  return txb.moveCall({
    arguments: [baby],
    target: `${babyPackageId}::capsule_baby::return_and_share`,
    typeArguments: [],
  });
}

export function editCapsuleBabyName(txb: TransactionBlock, { auth, baby, newName }: EditBabyNameOptions) {
  return txb.moveCall({
    arguments: [typeof baby == "string" ? txb.object(baby) : baby, txb.pure(newName), auth],
    target: `${babyPackageId}::capsule_baby::edit_baby_name`,
    typeArguments: [],
  });
}

export function createOrganizationFromPublishReceipt(txb: TransactionBlock, receipt: string) {
  let owner = ownerKeypair.getPublicKey().toSuiAddress();

  return txb.moveCall({
    arguments: [txb.object(receipt), txb.pure(owner)],
    target: `${ownershipPackageId}::organization::create_from_receipt`,
    typeArguments: [],
  });
}

export function addOrganizationPackage(
  txb: TransactionBlock,
  { auth, receipt, organization }: AddOrganizationPackageOptions
) {
  return txb.moveCall({
    arguments: [txb.object(receipt), typeof organization == "string" ? txb.object(organization) : organization, auth],
    target: `${ownershipPackageId}::organization::add_package`,
    typeArguments: [],
  });
}

export function removeOrganizationPackage(
  txb: TransactionBlock,
  { auth, packageId, organization }: RemoveOrganizationPackageOptions
) {
  return txb.moveCall({
    arguments: [typeof organization == "string" ? txb.object(organization) : organization, txb.pure(packageId), auth],
    target: `${ownershipPackageId}::organization::remove_package`,
    typeArguments: [],
  });
}

export function destroyOrganization(txb: TransactionBlock, { auth, organization }: DestroyOrganizationOptions) {
  return txb.moveCall({
    arguments: [typeof organization == "string" ? txb.object(organization) : organization, auth],
    target: `${ownershipPackageId}::organization::destroy`,
    typeArguments: [],
  });
}

export function returnAndShareOrganization(txb: TransactionBlock, organization: TransactionArgument) {
  return txb.moveCall({
    arguments: [organization],
    target: `${ownershipPackageId}::organization::return_and_share`,
    typeArguments: [],
  });
}

export function endorseOrganization(
  txb: TransactionBlock,
  { address, auth, organization }: OrganizationEndorsementOptions
) {
  return txb.moveCall({
    arguments: [typeof organization == "string" ? txb.object(organization) : organization, txb.pure(address), auth],
    target: `${ownershipPackageId}::organization::add_endorsement`,
    typeArguments: [],
  });
}

export function unendorseOrganization(
  txb: TransactionBlock,
  { address, auth, organization }: OrganizationEndorsementOptions
) {
  return txb.moveCall({
    arguments: [typeof organization == "string" ? txb.object(organization) : organization, txb.pure(address), auth],
    target: `${ownershipPackageId}::organization::remove_endorsement`,
    typeArguments: [],
  });
}

export function setOrganizationRoleForAgent(
  txb: TransactionBlock,
  { agent, role, auth, organization }: SetOrganizationRoleForAgentOptions
) {
  return txb.moveCall({
    arguments: [
      typeof organization == "string" ? txb.object(organization) : organization,
      txb.pure(agent),
      txb.pure(role),
      auth,
    ],
    target: `${ownershipPackageId}::organization::set_role_for_agent`,
    typeArguments: [],
  });
}

export function grantPermissiontoOrganizationRole(
  txb: TransactionBlock,
  { permissionType, role, auth, organization }: OrganizationPermissionRoleOptions
) {
  return txb.moveCall({
    arguments: [typeof organization == "string" ? txb.object(organization) : organization, txb.pure(role), auth],
    target: `${ownershipPackageId}::organization::grant_permission_to_role`,
    typeArguments: [permissionType],
  });
}

export function revokePermissionFromOrganizationRole(
  txb: TransactionBlock,
  { permissionType, role, auth, organization }: OrganizationPermissionRoleOptions
) {
  return txb.moveCall({
    arguments: [typeof organization == "string" ? txb.object(organization) : organization, txb.pure(role), auth],
    target: `${ownershipPackageId}::organization::revoke_permission_from_role`,
    typeArguments: [permissionType],
  });
}

export function claimOrganizationPermissions(txb: TransactionBlock, organization: TransactionArgument | string) {
  return txb.moveCall({
    arguments: [typeof organization == "string" ? txb.object(organization) : organization],
    target: `${ownershipPackageId}::organization::claim_permissions`,
    typeArguments: [],
  });
}
