import { PUBLISHED_AT } from "..";
import { ObjectArg, Type, obj, pure, vector } from "../../_framework/util";
import {
  ObjectId,
  TransactionArgument,
  TransactionBlock,
} from "@mysten/sui.js";

export function empty(txb: TransactionBlock) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action_set::empty`,
    arguments: [],
  });
}

export function new_(
  txb: TransactionBlock,
  contents: Array<ObjectArg> | TransactionArgument
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action_set::new`,
    arguments: [
      vector(
        txb,
        `0xf167c2f8449be4da16dcf9633206228068d672f2dd2d8d8d06c5cac90dc3d1ac::action::Action`,
        contents
      ),
    ],
  });
}

export interface IntersectionArgs {
  self: ObjectArg;
  filter: ObjectArg;
}

export function intersection(txb: TransactionBlock, args: IntersectionArgs) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action_set::intersection`,
    arguments: [obj(txb, args.self), obj(txb, args.filter)],
  });
}

export interface MergeArgs {
  self: ObjectArg;
  new: ObjectArg;
}

export function merge(txb: TransactionBlock, args: MergeArgs) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action_set::merge`,
    arguments: [obj(txb, args.self), obj(txb, args.new)],
  });
}

export interface AddActionForObjectsArgs {
  set: ObjectArg;
  objects: Array<ObjectId | TransactionArgument> | TransactionArgument;
}

export function addActionForObjects(
  txb: TransactionBlock,
  typeArg: Type,
  args: AddActionForObjectsArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action_set::add_action_for_objects`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.set),
      pure(txb, args.objects, `vector<0x2::object::ID>`),
    ],
  });
}

export interface AddActionForTypesArgs {
  set: ObjectArg;
  types: Array<ObjectArg> | TransactionArgument;
}

export function addActionForTypes(
  txb: TransactionBlock,
  typeArg: Type,
  args: AddActionForTypesArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action_set::add_action_for_types`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.set),
      vector(
        txb,
        `0xfcb0f4008277fc0703d09b7e1245918ce5c9b6f9f65a42eed806430903d72946::struct_tag::StructTag`,
        args.types
      ),
    ],
  });
}

export function addGeneral(
  txb: TransactionBlock,
  typeArg: Type,
  set: ObjectArg
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action_set::add_general`,
    typeArguments: [typeArg],
    arguments: [obj(txb, set)],
  });
}

export interface AddGeneral_Args {
  set: ObjectArg;
  actions: Array<ObjectArg> | TransactionArgument;
}

export function addGeneral_(txb: TransactionBlock, args: AddGeneral_Args) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action_set::add_general_`,
    arguments: [
      obj(txb, args.set),
      vector(
        txb,
        `0xf167c2f8449be4da16dcf9633206228068d672f2dd2d8d8d06c5cac90dc3d1ac::action::Action`,
        args.actions
      ),
    ],
  });
}

export function general(txb: TransactionBlock, set: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action_set::general`,
    arguments: [obj(txb, set)],
  });
}

export function onObjects(txb: TransactionBlock, set: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action_set::on_objects`,
    arguments: [obj(txb, set)],
  });
}

export function onTypes(txb: TransactionBlock, set: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action_set::on_types`,
    arguments: [obj(txb, set)],
  });
}

export interface RemoveActionForObjectsArgs {
  set: ObjectArg;
  objects: Array<ObjectId | TransactionArgument> | TransactionArgument;
}

export function removeActionForObjects(
  txb: TransactionBlock,
  typeArg: Type,
  args: RemoveActionForObjectsArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action_set::remove_action_for_objects`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.set),
      pure(txb, args.objects, `vector<0x2::object::ID>`),
    ],
  });
}

export interface RemoveActionForTypesArgs {
  set: ObjectArg;
  types: Array<ObjectArg> | TransactionArgument;
}

export function removeActionForTypes(
  txb: TransactionBlock,
  typeArg: Type,
  args: RemoveActionForTypesArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action_set::remove_action_for_types`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.set),
      vector(
        txb,
        `0xfcb0f4008277fc0703d09b7e1245918ce5c9b6f9f65a42eed806430903d72946::struct_tag::StructTag`,
        args.types
      ),
    ],
  });
}

export interface RemoveAllActionsForObjectsArgs {
  set: ObjectArg;
  objects: Array<ObjectId | TransactionArgument> | TransactionArgument;
}

export function removeAllActionsForObjects(
  txb: TransactionBlock,
  args: RemoveAllActionsForObjectsArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action_set::remove_all_actions_for_objects`,
    arguments: [
      obj(txb, args.set),
      pure(txb, args.objects, `vector<0x2::object::ID>`),
    ],
  });
}

export interface RemoveAllActionsForTypesArgs {
  set: ObjectArg;
  types: Array<ObjectArg> | TransactionArgument;
}

export function removeAllActionsForTypes(
  txb: TransactionBlock,
  args: RemoveAllActionsForTypesArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action_set::remove_all_actions_for_types`,
    arguments: [
      obj(txb, args.set),
      vector(
        txb,
        `0xfcb0f4008277fc0703d09b7e1245918ce5c9b6f9f65a42eed806430903d72946::struct_tag::StructTag`,
        args.types
      ),
    ],
  });
}

export function removeAllGeneral(txb: TransactionBlock, set: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action_set::remove_all_general`,
    arguments: [obj(txb, set)],
  });
}

export function removeGeneral(
  txb: TransactionBlock,
  typeArg: Type,
  set: ObjectArg
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::action_set::remove_general`,
    typeArguments: [typeArg],
    arguments: [obj(txb, set)],
  });
}
