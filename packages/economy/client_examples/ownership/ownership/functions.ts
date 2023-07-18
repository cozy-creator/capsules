import { PUBLISHED_AT } from "..";
import {
  GenericArg,
  ObjectArg,
  Type,
  generic,
  obj,
  pure,
} from "../../_framework/util";
import { TransactionArgument, TransactionBlock } from "@mysten/sui.js";

export interface DestroyArgs {
  uid: ObjectArg;
  auth: ObjectArg;
}

export function destroy(txb: TransactionBlock, args: DestroyArgs) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::ownership::destroy`,
    arguments: [obj(txb, args.uid), obj(txb, args.auth)],
  });
}

export interface TransferArgs {
  uid: ObjectArg;
  newOwner: string | TransactionArgument | TransactionArgument | null;
  auth: ObjectArg;
}

export function transfer(txb: TransactionBlock, args: TransferArgs) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::ownership::transfer`,
    arguments: [
      obj(txb, args.uid),
      pure(txb, args.newOwner, `0x1::option::Option<address>`),
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
    target: `${PUBLISHED_AT}::ownership::add_object_id`,
    arguments: [obj(txb, args.uid), obj(txb, args.auth)],
  });
}

export function beginWithObjectId(txb: TransactionBlock, uid: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::ownership::begin_with_object_id`,
    arguments: [obj(txb, uid)],
  });
}

export interface CanActAsAddressOnObjectArgs {
  principal: string | TransactionArgument;
  uid: ObjectArg;
  auth: ObjectArg;
}

export function canActAsAddressOnObject(
  txb: TransactionBlock,
  typeArg: Type,
  args: CanActAsAddressOnObjectArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::ownership::can_act_as_address_on_object`,
    typeArguments: [typeArg],
    arguments: [
      pure(txb, args.principal, `address`),
      obj(txb, args.uid),
      obj(txb, args.auth),
    ],
  });
}

export interface AsOwnedObjectArgs {
  uid: ObjectArg;
  typedId: ObjectArg;
  auth: ObjectArg;
}

export function asOwnedObject(
  txb: TransactionBlock,
  typeArg: Type,
  args: AsOwnedObjectArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::ownership::as_owned_object`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.uid),
      obj(txb, args.typedId),
      obj(txb, args.auth),
    ],
  });
}

export interface AsSharedObjectArgs {
  uid: ObjectArg;
  typedId: ObjectArg;
  owner: string | TransactionArgument;
  auth: ObjectArg;
}

export function asSharedObject(
  txb: TransactionBlock,
  typeArgs: [Type, Type],
  args: AsSharedObjectArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::ownership::as_shared_object`,
    typeArguments: typeArgs,
    arguments: [
      obj(txb, args.uid),
      obj(txb, args.typedId),
      pure(txb, args.owner, `address`),
      obj(txb, args.auth),
    ],
  });
}

export interface AsSharedObject_Args {
  uid: ObjectArg;
  typedId: ObjectArg;
  owner: string | TransactionArgument;
  transferAuth: string | TransactionArgument;
  auth: ObjectArg;
}

export function asSharedObject_(
  txb: TransactionBlock,
  typeArg: Type,
  args: AsSharedObject_Args,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::ownership::as_shared_object_`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.uid),
      obj(txb, args.typedId),
      pure(txb, args.owner, `address`),
      pure(txb, args.transferAuth, `address`),
      obj(txb, args.auth),
    ],
  });
}

export interface AssertValidInitializationArgs {
  uid: ObjectArg;
  typedId: ObjectArg;
  auth: ObjectArg;
}

export function assertValidInitialization(
  txb: TransactionBlock,
  typeArg: Type,
  args: AssertValidInitializationArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::ownership::assert_valid_initialization`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.uid),
      obj(txb, args.typedId),
      obj(txb, args.auth),
    ],
  });
}

export interface CanActAsDeclaringPackageArgs {
  uid: ObjectArg;
  auth: ObjectArg;
}

export function canActAsDeclaringPackage(
  txb: TransactionBlock,
  typeArg: Type,
  args: CanActAsDeclaringPackageArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::ownership::can_act_as_declaring_package`,
    typeArguments: [typeArg],
    arguments: [obj(txb, args.uid), obj(txb, args.auth)],
  });
}

export interface CanActAsDeclaringPackage_Args {
  obj: GenericArg;
  auth: ObjectArg;
}

export function canActAsDeclaringPackage_(
  txb: TransactionBlock,
  typeArgs: [Type, Type],
  args: CanActAsDeclaringPackage_Args,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::ownership::can_act_as_declaring_package_`,
    typeArguments: typeArgs,
    arguments: [generic(txb, `${typeArgs[0]}`, args.obj), obj(txb, args.auth)],
  });
}

export interface CanActAsOwnerArgs {
  uid: ObjectArg;
  auth: ObjectArg;
}

export function canActAsOwner(
  txb: TransactionBlock,
  typeArg: Type,
  args: CanActAsOwnerArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::ownership::can_act_as_owner`,
    typeArguments: [typeArg],
    arguments: [obj(txb, args.uid), obj(txb, args.auth)],
  });
}

export interface CanActAsTransferAuthArgs {
  uid: ObjectArg;
  auth: ObjectArg;
}

export function canActAsTransferAuth(
  txb: TransactionBlock,
  typeArg: Type,
  args: CanActAsTransferAuthArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::ownership::can_act_as_transfer_auth`,
    typeArguments: [typeArg],
    arguments: [obj(txb, args.uid), obj(txb, args.auth)],
  });
}

export interface CanBorrowUidMutArgs {
  uid: ObjectArg;
  auth: ObjectArg;
}

export function canBorrowUidMut(
  txb: TransactionBlock,
  args: CanBorrowUidMutArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::ownership::can_borrow_uid_mut`,
    arguments: [obj(txb, args.uid), obj(txb, args.auth)],
  });
}

export interface EjectTransferAuthArgs {
  uid: ObjectArg;
  auth: ObjectArg;
}

export function ejectTransferAuth(
  txb: TransactionBlock,
  args: EjectTransferAuthArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::ownership::eject_transfer_auth`,
    arguments: [obj(txb, args.uid), obj(txb, args.auth)],
  });
}

export interface FreezeTransferArgs {
  uid: ObjectArg;
  auth: ObjectArg;
}

export function freezeTransfer(
  txb: TransactionBlock,
  args: FreezeTransferArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::ownership::freeze_transfer`,
    arguments: [obj(txb, args.uid), obj(txb, args.auth)],
  });
}

export function getOwner(txb: TransactionBlock, uid: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::ownership::get_owner`,
    arguments: [obj(txb, uid)],
  });
}

export function getPackageAuthority(txb: TransactionBlock, uid: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::ownership::get_package_authority`,
    arguments: [obj(txb, uid)],
  });
}

export function getTransferAuthority(txb: TransactionBlock, uid: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::ownership::get_transfer_authority`,
    arguments: [obj(txb, uid)],
  });
}

export function getType(txb: TransactionBlock, uid: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::ownership::get_type`,
    arguments: [obj(txb, uid)],
  });
}

export function isDestroyed(txb: TransactionBlock, uid: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::ownership::is_destroyed`,
    arguments: [obj(txb, uid)],
  });
}

export function isFrozen(txb: TransactionBlock, uid: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::ownership::is_frozen`,
    arguments: [obj(txb, uid)],
  });
}

export function isInitialized(txb: TransactionBlock, uid: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::ownership::is_initialized`,
    arguments: [obj(txb, uid)],
  });
}

export interface MakeOwnerImmutableArgs {
  uid: ObjectArg;
  auth: ObjectArg;
}

export function makeOwnerImmutable(
  txb: TransactionBlock,
  args: MakeOwnerImmutableArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::ownership::make_owner_immutable`,
    arguments: [obj(txb, args.uid), obj(txb, args.auth)],
  });
}

export interface SetTransferAuthArgs {
  uid: ObjectArg;
  newAuth: string | TransactionArgument;
  auth: ObjectArg;
}

export function setTransferAuth(
  txb: TransactionBlock,
  args: SetTransferAuthArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::ownership::set_transfer_auth`,
    arguments: [
      obj(txb, args.uid),
      pure(txb, args.newAuth, `address`),
      obj(txb, args.auth),
    ],
  });
}

export interface UnfreezeTransferArgs {
  uid: ObjectArg;
  auth: ObjectArg;
}

export function unfreezeTransfer(
  txb: TransactionBlock,
  args: UnfreezeTransferArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::ownership::unfreeze_transfer`,
    arguments: [obj(txb, args.uid), obj(txb, args.auth)],
  });
}
