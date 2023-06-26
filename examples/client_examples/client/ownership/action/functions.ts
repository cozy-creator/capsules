import { PUBLISHED_AT } from "..";
import { ObjectArg, Type, obj, vector } from "../../_framework/util";
import { TransactionArgument, TransactionBlock } from "@mysten/sui.js";

export function contains(
  txb: TransactionBlock,
  typeArg: Type,
  actions: Array<ObjectArg> | TransactionArgument
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action::contains`,
    typeArguments: [typeArg],
    arguments: [
      vector(
        txb,
        `0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::action::Action`,
        actions
      ),
    ],
  });
}

export function new_(txb: TransactionBlock, typeArg: Type) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action::new`,
    typeArguments: [typeArg],
    arguments: [],
  });
}

export interface AddArgs {
  existing: Array<ObjectArg> | TransactionArgument;
  new: Array<ObjectArg> | TransactionArgument;
}

export function add(txb: TransactionBlock, args: AddArgs) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action::add`,
    arguments: [
      vector(
        txb,
        `0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::action::Action`,
        args.existing
      ),
      vector(
        txb,
        `0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::action::Action`,
        args.new
      ),
    ],
  });
}

export interface IntersectionArgs {
  actions: Array<ObjectArg> | TransactionArgument;
  filter: Array<ObjectArg> | TransactionArgument;
}

export function intersection(txb: TransactionBlock, args: IntersectionArgs) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action::intersection`,
    arguments: [
      vector(
        txb,
        `0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::action::Action`,
        args.actions
      ),
      vector(
        txb,
        `0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::action::Action`,
        args.filter
      ),
    ],
  });
}

export interface Add_Args {
  existing: Array<ObjectArg> | TransactionArgument;
  new: Array<ObjectArg> | TransactionArgument;
}

export function add_(txb: TransactionBlock, args: Add_Args) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action::add_`,
    arguments: [
      vector(
        txb,
        `0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::action::Action`,
        args.existing
      ),
      vector(
        txb,
        `0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::action::Action`,
        args.new
      ),
    ],
  });
}

export function admin(txb: TransactionBlock) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action::admin`,
    arguments: [],
  });
}

export function containsAdmin(
  txb: TransactionBlock,
  actions: Array<ObjectArg> | TransactionArgument
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action::contains_admin`,
    arguments: [
      vector(
        txb,
        `0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::action::Action`,
        actions
      ),
    ],
  });
}

export function containsExcludingManager(
  txb: TransactionBlock,
  typeArg: Type,
  actions: Array<ObjectArg> | TransactionArgument
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action::contains_excluding_manager`,
    typeArguments: [typeArg],
    arguments: [
      vector(
        txb,
        `0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::action::Action`,
        actions
      ),
    ],
  });
}

export function containsManager(
  txb: TransactionBlock,
  actions: Array<ObjectArg> | TransactionArgument
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action::contains_manager`,
    arguments: [
      vector(
        txb,
        `0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::action::Action`,
        actions
      ),
    ],
  });
}

export function isAdminAction(txb: TransactionBlock, typeArg: Type) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action::is_admin_action`,
    typeArguments: [typeArg],
    arguments: [],
  });
}

export function isAdminAction_(txb: TransactionBlock, action: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action::is_admin_action_`,
    arguments: [obj(txb, action)],
  });
}

export function isAny(txb: TransactionBlock, typeArg: Type) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action::is_any`,
    typeArguments: [typeArg],
    arguments: [],
  });
}

export function isAny_(txb: TransactionBlock, action: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action::is_any_`,
    arguments: [obj(txb, action)],
  });
}

export function isManagerAction(txb: TransactionBlock, typeArg: Type) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action::is_manager_action`,
    typeArguments: [typeArg],
    arguments: [],
  });
}

export function isManagerAction_(txb: TransactionBlock, action: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action::is_manager_action_`,
    arguments: [obj(txb, action)],
  });
}

export function manager(txb: TransactionBlock) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action::manager`,
    arguments: [],
  });
}

export interface VecMapIntersectionArgs {
  self: ObjectArg;
  generalFilter: Array<ObjectArg> | TransactionArgument;
  specificFilter: ObjectArg;
}

export function vecMapIntersection(
  txb: TransactionBlock,
  typeArg: Type,
  args: VecMapIntersectionArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action::vec_map_intersection`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.self),
      vector(
        txb,
        `0xe94495c751b3227f6855aba6917acb9b46ff07b887290d614768ab6c36d5d1fc::action::Action`,
        args.generalFilter
      ),
      obj(txb, args.specificFilter),
    ],
  });
}

export interface VecMapJoinArgs {
  existing: ObjectArg;
  new: ObjectArg;
}

export function vecMapJoin(
  txb: TransactionBlock,
  typeArg: Type,
  args: VecMapJoinArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action::vec_map_join`,
    typeArguments: [typeArg],
    arguments: [obj(txb, args.existing), obj(txb, args.new)],
  });
}
