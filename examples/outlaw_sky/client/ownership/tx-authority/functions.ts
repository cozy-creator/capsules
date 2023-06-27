import { PUBLISHED_AT } from "..";
import {
  GenericArg,
  ObjectArg,
  Type,
  generic,
  obj,
  pure,
  vector,
} from "../../_framework/util";
import {
  ObjectId,
  TransactionArgument,
  TransactionBlock,
} from "@mysten/sui.js";

export function empty(txb: TransactionBlock) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::empty`,
    arguments: [],
  });
}

export interface AddActionsInternalArgs {
  principal: string | TransactionArgument;
  agent: string | TransactionArgument;
  newActions: Array<ObjectArg> | TransactionArgument;
  auth: ObjectArg;
}

export function addActionsInternal(
  txb: TransactionBlock,
  args: AddActionsInternalArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::add_actions_internal`,
    arguments: [
      pure(txb, args.principal, `address`),
      pure(txb, args.agent, `address`),
      vector(
        txb,
        `0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::action::Action`,
        args.newActions
      ),
      obj(txb, args.auth),
    ],
  });
}

export interface AddObjectIdArgs {
  uid: ObjectArg;
  auth: ObjectArg;
}

export function addObjectId(txb: TransactionBlock, args: AddObjectIdArgs) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::add_object_id`,
    arguments: [obj(txb, args.uid), obj(txb, args.auth)],
  });
}

export interface AddOrganizationInternalArgs {
  packages: Array<ObjectId | TransactionArgument> | TransactionArgument;
  principal: string | TransactionArgument;
  auth: ObjectArg;
}

export function addOrganizationInternal(
  txb: TransactionBlock,
  args: AddOrganizationInternalArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::add_organization_internal`,
    arguments: [
      pure(txb, args.packages, `vector<0x2::object::ID>`),
      pure(txb, args.principal, `address`),
      obj(txb, args.auth),
    ],
  });
}

export interface AddPackageWitnessArgs {
  witness: GenericArg;
  auth: ObjectArg;
}

export function addPackageWitness(
  txb: TransactionBlock,
  typeArgs: [Type, Type],
  args: AddPackageWitnessArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::add_package_witness`,
    typeArguments: typeArgs,
    arguments: [
      generic(txb, `${typeArgs[0]}`, args.witness),
      obj(txb, args.auth),
    ],
  });
}

export function addSigner(txb: TransactionBlock, auth: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::add_signer`,
    arguments: [obj(txb, auth)],
  });
}

export interface AddTypeArgs {
  cap: GenericArg;
  auth: ObjectArg;
}

export function addType(
  txb: TransactionBlock,
  typeArg: Type,
  args: AddTypeArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::add_type`,
    typeArguments: [typeArg],
    arguments: [generic(txb, `${typeArg}`, args.cap), obj(txb, args.auth)],
  });
}

export function agents(txb: TransactionBlock, auth: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::agents`,
    arguments: [obj(txb, auth)],
  });
}

export function begin(txb: TransactionBlock) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::begin`,
    arguments: [],
  });
}

export function beginWithObjectId(txb: TransactionBlock, uid: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::begin_with_object_id`,
    arguments: [obj(txb, uid)],
  });
}

export function beginWithPackageWitness(
  txb: TransactionBlock,
  typeArgs: [Type, Type],
  witness: GenericArg
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::begin_with_package_witness`,
    typeArguments: typeArgs,
    arguments: [generic(txb, `${typeArgs[0]}`, witness)],
  });
}

export function beginWithType(
  txb: TransactionBlock,
  typeArg: Type,
  cap: GenericArg
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::begin_with_type`,
    typeArguments: [typeArg],
    arguments: [generic(txb, `${typeArg}`, cap)],
  });
}

export interface CanActAsAddressArgs {
  principal: string | TransactionArgument;
  auth: ObjectArg;
}

export function canActAsAddress(
  txb: TransactionBlock,
  typeArg: Type,
  args: CanActAsAddressArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::can_act_as_address`,
    typeArguments: [typeArg],
    arguments: [pure(txb, args.principal, `address`), obj(txb, args.auth)],
  });
}

export interface CanActAsAddressOnObjectArgs {
  principal: string | TransactionArgument;
  type: ObjectArg;
  objectId: ObjectId | TransactionArgument;
  auth: ObjectArg;
}

export function canActAsAddressOnObject(
  txb: TransactionBlock,
  typeArg: Type,
  args: CanActAsAddressOnObjectArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::can_act_as_address_on_object`,
    typeArguments: [typeArg],
    arguments: [
      pure(txb, args.principal, `address`),
      obj(txb, args.type),
      pure(txb, args.objectId, `0x2::object::ID`),
      obj(txb, args.auth),
    ],
  });
}

export interface CanActAsIdArgs {
  obj: GenericArg;
  auth: ObjectArg;
}

export function canActAsId(
  txb: TransactionBlock,
  typeArgs: [Type, Type],
  args: CanActAsIdArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::can_act_as_id`,
    typeArguments: typeArgs,
    arguments: [generic(txb, `${typeArgs[0]}`, args.obj), obj(txb, args.auth)],
  });
}

export interface CanActAsId_Args {
  id: ObjectId | TransactionArgument;
  auth: ObjectArg;
}

export function canActAsId_(
  txb: TransactionBlock,
  typeArg: Type,
  args: CanActAsId_Args
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::can_act_as_id_`,
    typeArguments: [typeArg],
    arguments: [pure(txb, args.id, `0x2::object::ID`), obj(txb, args.auth)],
  });
}

export function canActAsPackage(
  txb: TransactionBlock,
  typeArgs: [Type, Type],
  auth: ObjectArg
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::can_act_as_package`,
    typeArguments: typeArgs,
    arguments: [obj(txb, auth)],
  });
}

export interface CanActAsPackage_Args {
  packageId: ObjectId | TransactionArgument;
  auth: ObjectArg;
}

export function canActAsPackage_(
  txb: TransactionBlock,
  typeArg: Type,
  args: CanActAsPackage_Args
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::can_act_as_package_`,
    typeArguments: [typeArg],
    arguments: [
      pure(txb, args.packageId, `0x2::object::ID`),
      obj(txb, args.auth),
    ],
  });
}

export function canActAsPackageExcludingManager(
  txb: TransactionBlock,
  typeArgs: [Type, Type],
  auth: ObjectArg
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::can_act_as_package_excluding_manager`,
    typeArguments: typeArgs,
    arguments: [obj(txb, auth)],
  });
}

export interface CanActAsPackageExcludingManager_Args {
  packageId: ObjectId | TransactionArgument;
  auth: ObjectArg;
}

export function canActAsPackageExcludingManager_(
  txb: TransactionBlock,
  typeArg: Type,
  args: CanActAsPackageExcludingManager_Args
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::can_act_as_package_excluding_manager_`,
    typeArguments: [typeArg],
    arguments: [
      pure(txb, args.packageId, `0x2::object::ID`),
      obj(txb, args.auth),
    ],
  });
}

export interface CanActAsPackageOnObjectArgs {
  type: ObjectArg;
  objectId: ObjectId | TransactionArgument;
  auth: ObjectArg;
}

export function canActAsPackageOnObject(
  txb: TransactionBlock,
  typeArgs: [Type, Type],
  args: CanActAsPackageOnObjectArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::can_act_as_package_on_object`,
    typeArguments: typeArgs,
    arguments: [
      obj(txb, args.type),
      pure(txb, args.objectId, `0x2::object::ID`),
      obj(txb, args.auth),
    ],
  });
}

export interface CanActAsPackageOnObject_Args {
  packageId: ObjectId | TransactionArgument;
  structTag: ObjectArg;
  objectId: ObjectId | TransactionArgument;
  auth: ObjectArg;
}

export function canActAsPackageOnObject_(
  txb: TransactionBlock,
  typeArg: Type,
  args: CanActAsPackageOnObject_Args
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::can_act_as_package_on_object_`,
    typeArguments: [typeArg],
    arguments: [
      pure(txb, args.packageId, `0x2::object::ID`),
      obj(txb, args.structTag),
      pure(txb, args.objectId, `0x2::object::ID`),
      obj(txb, args.auth),
    ],
  });
}

export interface CanActAsPackageOptArgs {
  packageMaybe: ObjectId | TransactionArgument | TransactionArgument | null;
  auth: ObjectArg;
}

export function canActAsPackageOpt(
  txb: TransactionBlock,
  typeArg: Type,
  args: CanActAsPackageOptArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::can_act_as_package_opt`,
    typeArguments: [typeArg],
    arguments: [
      pure(txb, args.packageMaybe, `0x1::option::Option<0x2::object::ID>`),
      obj(txb, args.auth),
    ],
  });
}

export function canActAsType(
  txb: TransactionBlock,
  typeArgs: [Type, Type],
  auth: ObjectArg
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::can_act_as_type`,
    typeArguments: typeArgs,
    arguments: [obj(txb, auth)],
  });
}

export function copy_(txb: TransactionBlock, auth: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::copy_`,
    arguments: [obj(txb, auth)],
  });
}

export interface HasKOrMoreAgentsWithActionArgs {
  principals: Array<string | TransactionArgument> | TransactionArgument;
  k: bigint | TransactionArgument;
  auth: ObjectArg;
}

export function hasKOrMoreAgentsWithAction(
  txb: TransactionBlock,
  typeArg: Type,
  args: HasKOrMoreAgentsWithActionArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::has_k_or_more_agents_with_action`,
    typeArguments: [typeArg],
    arguments: [
      pure(txb, args.principals, `vector<address>`),
      pure(txb, args.k, `u64`),
      obj(txb, args.auth),
    ],
  });
}

export interface IsManagerArgs {
  principal: string | TransactionArgument;
  auth: ObjectArg;
}

export function isManager(txb: TransactionBlock, args: IsManagerArgs) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::is_manager`,
    arguments: [pure(txb, args.principal, `address`), obj(txb, args.auth)],
  });
}

export function isModuleAuthority(
  txb: TransactionBlock,
  typeArgs: [Type, Type]
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::is_module_authority`,
    typeArguments: typeArgs,
    arguments: [],
  });
}

export function lookupOrganizationForPackage(
  txb: TransactionBlock,
  typeArg: Type,
  auth: ObjectArg
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::lookup_organization_for_package`,
    typeArguments: [typeArg],
    arguments: [obj(txb, auth)],
  });
}

export interface LookupOrganizationForPackage_Args {
  packageId: ObjectId | TransactionArgument;
  auth: ObjectArg;
}

export function lookupOrganizationForPackage_(
  txb: TransactionBlock,
  args: LookupOrganizationForPackage_Args
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::lookup_organization_for_package_`,
    arguments: [
      pure(txb, args.packageId, `0x2::object::ID`),
      obj(txb, args.auth),
    ],
  });
}

export interface MergeActionSetInternalArgs {
  principal: string | TransactionArgument;
  agent: string | TransactionArgument;
  newSet: ObjectArg;
  auth: ObjectArg;
}

export function mergeActionSetInternal(
  txb: TransactionBlock,
  args: MergeActionSetInternalArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::merge_action_set_internal`,
    arguments: [
      pure(txb, args.principal, `address`),
      pure(txb, args.agent, `address`),
      obj(txb, args.newSet),
      obj(txb, args.auth),
    ],
  });
}

export function newInternal(
  txb: TransactionBlock,
  principal: string | TransactionArgument
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::new_internal`,
    arguments: [pure(txb, principal, `address`)],
  });
}

export function newInternal_(
  txb: TransactionBlock,
  typeArg: Type,
  principal: string | TransactionArgument
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::new_internal_`,
    typeArguments: [typeArg],
    arguments: [pure(txb, principal, `address`)],
  });
}

export function organizations(txb: TransactionBlock, auth: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::organizations`,
    arguments: [obj(txb, auth)],
  });
}

export interface TallyAgentsWithActionArgs {
  principals: Array<string | TransactionArgument> | TransactionArgument;
  auth: ObjectArg;
}

export function tallyAgentsWithAction(
  txb: TransactionBlock,
  typeArg: Type,
  args: TallyAgentsWithActionArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::tally_agents_with_action`,
    typeArguments: [typeArg],
    arguments: [
      pure(txb, args.principals, `vector<address>`),
      obj(txb, args.auth),
    ],
  });
}

export function witnessString(txb: TransactionBlock, typeArg: Type) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::tx_authority::witness_string`,
    typeArguments: [typeArg],
    arguments: [],
  });
}
