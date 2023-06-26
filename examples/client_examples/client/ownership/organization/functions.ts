import { PUBLISHED_AT } from "..";
import { ObjectArg, Type, obj, pure } from "../../_framework/util";
import {
  ObjectId,
  TransactionArgument,
  TransactionBlock,
} from "@mysten/sui.js";

export function uid(txb: TransactionBlock, organization: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::uid`,
    arguments: [obj(txb, organization)],
  });
}

export interface DestroyArgs {
  organization: ObjectArg;
  auth: ObjectArg;
}

export function destroy(txb: TransactionBlock, args: DestroyArgs) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::destroy`,
    arguments: [obj(txb, args.organization), obj(txb, args.auth)],
  });
}

export function createInternal(
  txb: TransactionBlock,
  owner: string | TransactionArgument
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::create_internal`,
    arguments: [pure(txb, owner, `address`)],
  });
}

export interface UidMutArgs {
  organization: ObjectArg;
  auth: ObjectArg;
}

export function uidMut(txb: TransactionBlock, args: UidMutArgs) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::uid_mut`,
    arguments: [obj(txb, args.organization), obj(txb, args.auth)],
  });
}

export function principal(txb: TransactionBlock, organization: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::principal`,
    arguments: [obj(txb, organization)],
  });
}

export function packages(txb: TransactionBlock, organization: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::packages`,
    arguments: [obj(txb, organization)],
  });
}

export function returnAndShare(txb: TransactionBlock, organization: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::return_and_share`,
    arguments: [obj(txb, organization)],
  });
}

export interface DeleteAgentArgs {
  org: ObjectArg;
  agent: string | TransactionArgument;
  auth: ObjectArg;
}

export function deleteAgent(txb: TransactionBlock, args: DeleteAgentArgs) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::delete_agent`,
    arguments: [
      obj(txb, args.org),
      pure(txb, args.agent, `address`),
      obj(txb, args.auth),
    ],
  });
}

export interface DeleteRoleAndAgentsArgs {
  org: ObjectArg;
  role: string | TransactionArgument;
  auth: ObjectArg;
}

export function deleteRoleAndAgents(
  txb: TransactionBlock,
  args: DeleteRoleAndAgentsArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::delete_role_and_agents`,
    arguments: [
      obj(txb, args.org),
      pure(txb, args.role, `0x1::string::String`),
      obj(txb, args.auth),
    ],
  });
}

export interface GrantActionToRoleArgs {
  org: ObjectArg;
  role: string | TransactionArgument;
  auth: ObjectArg;
}

export function grantActionToRole(
  txb: TransactionBlock,
  typeArg: Type,
  args: GrantActionToRoleArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::grant_action_to_role`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.org),
      pure(txb, args.role, `0x1::string::String`),
      obj(txb, args.auth),
    ],
  });
}

export interface RevokeActionFromRoleArgs {
  org: ObjectArg;
  role: string | TransactionArgument;
  auth: ObjectArg;
}

export function revokeActionFromRole(
  txb: TransactionBlock,
  typeArg: Type,
  args: RevokeActionFromRoleArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::revoke_action_from_role`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.org),
      pure(txb, args.role, `0x1::string::String`),
      obj(txb, args.auth),
    ],
  });
}

export interface SetRoleForAgentArgs {
  org: ObjectArg;
  agent: string | TransactionArgument;
  role: string | TransactionArgument;
  auth: ObjectArg;
}

export function setRoleForAgent(
  txb: TransactionBlock,
  args: SetRoleForAgentArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::set_role_for_agent`,
    arguments: [
      obj(txb, args.org),
      pure(txb, args.agent, `address`),
      pure(txb, args.role, `0x1::string::String`),
      obj(txb, args.auth),
    ],
  });
}

export interface AddEndorsementArgs {
  org: ObjectArg;
  from: string | TransactionArgument;
  auth: ObjectArg;
}

export function addEndorsement(
  txb: TransactionBlock,
  args: AddEndorsementArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::add_endorsement`,
    arguments: [
      obj(txb, args.org),
      pure(txb, args.from, `address`),
      obj(txb, args.auth),
    ],
  });
}

export interface AddEndorsement_Args {
  organization: ObjectArg;
  from: string | TransactionArgument;
}

export function addEndorsement_(
  txb: TransactionBlock,
  args: AddEndorsement_Args
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::add_endorsement_`,
    arguments: [obj(txb, args.organization), pure(txb, args.from, `address`)],
  });
}

export interface AddPackageArgs {
  receipt: ObjectArg;
  organization: ObjectArg;
  auth: ObjectArg;
}

export function addPackage(txb: TransactionBlock, args: AddPackageArgs) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::add_package`,
    arguments: [
      obj(txb, args.receipt),
      obj(txb, args.organization),
      obj(txb, args.auth),
    ],
  });
}

export interface AddPackage_Args {
  organization: ObjectArg;
  receipt: ObjectArg;
}

export function addPackage_(txb: TransactionBlock, args: AddPackage_Args) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::add_package_`,
    arguments: [obj(txb, args.organization), obj(txb, args.receipt)],
  });
}

export interface AddPackageFromStoredArgs {
  organization: ObjectArg;
  package: ObjectArg;
  auth: ObjectArg;
}

export function addPackageFromStored(
  txb: TransactionBlock,
  args: AddPackageFromStoredArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::add_package_from_stored`,
    arguments: [
      obj(txb, args.organization),
      obj(txb, args.package),
      obj(txb, args.auth),
    ],
  });
}

export interface AddPackageFromStored_Args {
  organization: ObjectArg;
  stored: ObjectArg;
}

export function addPackageFromStored_(
  txb: TransactionBlock,
  args: AddPackageFromStored_Args
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::add_package_from_stored_`,
    arguments: [obj(txb, args.organization), obj(txb, args.stored)],
  });
}

export interface AddPackageInternalArgs {
  receipt: ObjectArg;
  organization: ObjectArg;
}

export function addPackageInternal(
  txb: TransactionBlock,
  args: AddPackageInternalArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::add_package_internal`,
    arguments: [obj(txb, args.receipt), obj(txb, args.organization)],
  });
}

export interface AddToTxAuthorityArgs {
  organization: ObjectArg;
  auth: ObjectArg;
}

export function addToTxAuthority(
  txb: TransactionBlock,
  args: AddToTxAuthorityArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::add_to_tx_authority`,
    arguments: [obj(txb, args.organization), obj(txb, args.auth)],
  });
}

export function assertLogin(
  txb: TransactionBlock,
  typeArg: Type,
  organization: ObjectArg
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::assert_login`,
    typeArguments: [typeArg],
    arguments: [obj(txb, organization)],
  });
}

export interface AssertLogin_Args {
  organization: ObjectArg;
  auth: ObjectArg;
}

export function assertLogin_(
  txb: TransactionBlock,
  typeArg: Type,
  args: AssertLogin_Args
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::assert_login_`,
    typeArguments: [typeArg],
    arguments: [obj(txb, args.organization), obj(txb, args.auth)],
  });
}

export function claimActions(txb: TransactionBlock, organization: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::claim_actions`,
    arguments: [obj(txb, organization)],
  });
}

export interface ClaimActions_Args {
  organization: ObjectArg;
  auth: ObjectArg;
}

export function claimActions_(txb: TransactionBlock, args: ClaimActions_Args) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::claim_actions_`,
    arguments: [obj(txb, args.organization), obj(txb, args.auth)],
  });
}

export interface ClaimActionsForAgentArgs {
  organization: ObjectArg;
  agent: string | TransactionArgument;
  auth: ObjectArg;
}

export function claimActionsForAgent(
  txb: TransactionBlock,
  args: ClaimActionsForAgentArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::claim_actions_for_agent`,
    arguments: [
      obj(txb, args.organization),
      pure(txb, args.agent, `address`),
      obj(txb, args.auth),
    ],
  });
}

export interface CreateFromPackageArgs {
  package: ObjectArg;
  owner: string | TransactionArgument;
}

export function createFromPackage(
  txb: TransactionBlock,
  args: CreateFromPackageArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::create_from_package`,
    arguments: [obj(txb, args.package), pure(txb, args.owner, `address`)],
  });
}

export function createFromPackage_(txb: TransactionBlock, stored: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::create_from_package_`,
    arguments: [obj(txb, stored)],
  });
}

export interface CreateFromReceiptArgs {
  receipt: ObjectArg;
  owner: string | TransactionArgument;
}

export function createFromReceipt(
  txb: TransactionBlock,
  args: CreateFromReceiptArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::create_from_receipt`,
    arguments: [obj(txb, args.receipt), pure(txb, args.owner, `address`)],
  });
}

export function createFromReceipt_(txb: TransactionBlock, receipt: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::create_from_receipt_`,
    arguments: [obj(txb, receipt)],
  });
}

export interface DeleteAgent_Args {
  organization: ObjectArg;
  agent: string | TransactionArgument;
}

export function deleteAgent_(txb: TransactionBlock, args: DeleteAgent_Args) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::delete_agent_`,
    arguments: [obj(txb, args.organization), pure(txb, args.agent, `address`)],
  });
}

export interface DeleteRoleAndAgents_Args {
  organization: ObjectArg;
  role: string | TransactionArgument;
}

export function deleteRoleAndAgents_(
  txb: TransactionBlock,
  args: DeleteRoleAndAgents_Args
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::delete_role_and_agents_`,
    arguments: [
      obj(txb, args.organization),
      pure(txb, args.role, `0x1::string::String`),
    ],
  });
}

export function destroy_(txb: TransactionBlock, organization: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::destroy_`,
    arguments: [obj(txb, organization)],
  });
}

export interface GrantActionToRole_Args {
  organization: ObjectArg;
  role: string | TransactionArgument;
}

export function grantActionToRole_(
  txb: TransactionBlock,
  typeArg: Type,
  args: GrantActionToRole_Args
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::grant_action_to_role_`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.organization),
      pure(txb, args.role, `0x1::string::String`),
    ],
  });
}

export interface IsEndorsedByArgs {
  org: ObjectArg;
  from: string | TransactionArgument;
}

export function isEndorsedBy(txb: TransactionBlock, args: IsEndorsedByArgs) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::is_endorsed_by`,
    arguments: [obj(txb, args.org), pure(txb, args.from, `address`)],
  });
}

export interface IsEndorsedByNumArgs {
  org: ObjectArg;
  endorsers: Array<string | TransactionArgument> | TransactionArgument;
}

export function isEndorsedByNum(
  txb: TransactionBlock,
  args: IsEndorsedByNumArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::is_endorsed_by_num`,
    arguments: [
      obj(txb, args.org),
      pure(txb, args.endorsers, `vector<address>`),
    ],
  });
}

export function packageUid(txb: TransactionBlock, package: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::package_uid`,
    arguments: [obj(txb, package)],
  });
}

export interface PackageUid_Args {
  organization: ObjectArg;
  packageId: ObjectId | TransactionArgument;
}

export function packageUid_(txb: TransactionBlock, args: PackageUid_Args) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::package_uid_`,
    arguments: [
      obj(txb, args.organization),
      pure(txb, args.packageId, `0x2::object::ID`),
    ],
  });
}

export function packageUidMut(txb: TransactionBlock, package: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::package_uid_mut`,
    arguments: [obj(txb, package)],
  });
}

export interface PackageUidMut_Args {
  organization: ObjectArg;
  packageId: ObjectId | TransactionArgument;
  auth: ObjectArg;
}

export function packageUidMut_(
  txb: TransactionBlock,
  args: PackageUidMut_Args
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::package_uid_mut_`,
    arguments: [
      obj(txb, args.organization),
      pure(txb, args.packageId, `0x2::object::ID`),
      obj(txb, args.auth),
    ],
  });
}

export interface RemoveEndorsementArgs {
  org: ObjectArg;
  from: string | TransactionArgument;
  auth: ObjectArg;
}

export function removeEndorsement(
  txb: TransactionBlock,
  args: RemoveEndorsementArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::remove_endorsement`,
    arguments: [
      obj(txb, args.org),
      pure(txb, args.from, `address`),
      obj(txb, args.auth),
    ],
  });
}

export interface RemoveEndorsement_Args {
  organization: ObjectArg;
  from: string | TransactionArgument;
}

export function removeEndorsement_(
  txb: TransactionBlock,
  args: RemoveEndorsement_Args
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::remove_endorsement_`,
    arguments: [obj(txb, args.organization), pure(txb, args.from, `address`)],
  });
}

export interface RemovePackageArgs {
  organization: ObjectArg;
  packageId: ObjectId | TransactionArgument;
  auth: ObjectArg;
}

export function removePackage(txb: TransactionBlock, args: RemovePackageArgs) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::remove_package`,
    arguments: [
      obj(txb, args.organization),
      pure(txb, args.packageId, `0x2::object::ID`),
      obj(txb, args.auth),
    ],
  });
}

export interface RemovePackage_Args {
  organization: ObjectArg;
  packageId: ObjectId | TransactionArgument;
  recipient: string | TransactionArgument;
}

export function removePackage_(
  txb: TransactionBlock,
  args: RemovePackage_Args
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::remove_package_`,
    arguments: [
      obj(txb, args.organization),
      pure(txb, args.packageId, `0x2::object::ID`),
      pure(txb, args.recipient, `address`),
    ],
  });
}

export interface RevokeActionFromRole_Args {
  organization: ObjectArg;
  role: string | TransactionArgument;
}

export function revokeActionFromRole_(
  txb: TransactionBlock,
  typeArg: Type,
  args: RevokeActionFromRole_Args
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::revoke_action_from_role_`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.organization),
      pure(txb, args.role, `0x1::string::String`),
    ],
  });
}

export interface SetRoleForAgent_Args {
  organization: ObjectArg;
  agent: string | TransactionArgument;
  role: string | TransactionArgument;
}

export function setRoleForAgent_(
  txb: TransactionBlock,
  args: SetRoleForAgent_Args
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::organization::set_role_for_agent_`,
    arguments: [
      obj(txb, args.organization),
      pure(txb, args.agent, `address`),
      pure(txb, args.role, `0x1::string::String`),
    ],
  });
}
