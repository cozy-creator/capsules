import { PUBLISHED_AT } from "..";
import { ObjectArg, Type, obj, pure } from "../../_framework/util";
import {
  ObjectId,
  TransactionArgument,
  TransactionBlock,
} from "@mysten/sui.js";

export function destroy(txb: TransactionBlock, person: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::person_helper::destroy`,
    arguments: [obj(txb, person)],
  });
}

export function create(txb: TransactionBlock) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::person_helper::create`,
    arguments: [],
  });
}

export interface AddActionForObjectsArgs {
  person: ObjectArg;
  agent: string | TransactionArgument;
  objects: Array<ObjectId | TransactionArgument> | TransactionArgument;
}

export function addActionForObjects(
  txb: TransactionBlock,
  typeArg: Type,
  args: AddActionForObjectsArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::person_helper::add_action_for_objects`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.person),
      pure(txb, args.agent, `address`),
      pure(txb, args.objects, `vector<0x2::object::ID>`),
    ],
  });
}

export interface AddActionForTypeArgs {
  person: ObjectArg;
  agent: string | TransactionArgument;
}

export function addActionForType(
  txb: TransactionBlock,
  typeArgs: [Type, Type],
  args: AddActionForTypeArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::person_helper::add_action_for_type`,
    typeArguments: typeArgs,
    arguments: [obj(txb, args.person), pure(txb, args.agent, `address`)],
  });
}

export interface AddGeneralActionArgs {
  person: ObjectArg;
  agent: string | TransactionArgument;
}

export function addGeneralAction(
  txb: TransactionBlock,
  typeArg: Type,
  args: AddGeneralActionArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::person_helper::add_general_action`,
    typeArguments: [typeArg],
    arguments: [obj(txb, args.person), pure(txb, args.agent, `address`)],
  });
}

export interface RemoveActionForObjectsFromAgentArgs {
  person: ObjectArg;
  agent: string | TransactionArgument;
  objects: Array<ObjectId | TransactionArgument> | TransactionArgument;
}

export function removeActionForObjectsFromAgent(
  txb: TransactionBlock,
  typeArg: Type,
  args: RemoveActionForObjectsFromAgentArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::person_helper::remove_action_for_objects_from_agent`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.person),
      pure(txb, args.agent, `address`),
      pure(txb, args.objects, `vector<0x2::object::ID>`),
    ],
  });
}

export interface RemoveActionForTypeFromAgentArgs {
  person: ObjectArg;
  agent: string | TransactionArgument;
}

export function removeActionForTypeFromAgent(
  txb: TransactionBlock,
  typeArgs: [Type, Type],
  args: RemoveActionForTypeFromAgentArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::person_helper::remove_action_for_type_from_agent`,
    typeArguments: typeArgs,
    arguments: [obj(txb, args.person), pure(txb, args.agent, `address`)],
  });
}

export interface RemoveAgentArgs {
  person: ObjectArg;
  agent: string | TransactionArgument;
}

export function removeAgent(txb: TransactionBlock, args: RemoveAgentArgs) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::person_helper::remove_agent`,
    arguments: [obj(txb, args.person), pure(txb, args.agent, `address`)],
  });
}

export interface RemoveAllActionsForTypeFromAgentArgs {
  person: ObjectArg;
  agent: string | TransactionArgument;
}

export function removeAllActionsForTypeFromAgent(
  txb: TransactionBlock,
  typeArg: Type,
  args: RemoveAllActionsForTypeFromAgentArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::person_helper::remove_all_actions_for_type_from_agent`,
    typeArguments: [typeArg],
    arguments: [obj(txb, args.person), pure(txb, args.agent, `address`)],
  });
}

export interface RemoveAllGeneralActionsFromAgentArgs {
  person: ObjectArg;
  agent: string | TransactionArgument;
}

export function removeAllGeneralActionsFromAgent(
  txb: TransactionBlock,
  args: RemoveAllGeneralActionsFromAgentArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::person_helper::remove_all_general_actions_from_agent`,
    arguments: [obj(txb, args.person), pure(txb, args.agent, `address`)],
  });
}

export interface RemoveGeneralActionFromAgentArgs {
  person: ObjectArg;
  agent: string | TransactionArgument;
}

export function removeGeneralActionFromAgent(
  txb: TransactionBlock,
  typeArg: Type,
  args: RemoveGeneralActionFromAgentArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::person_helper::remove_general_action_from_agent`,
    typeArguments: [typeArg],
    arguments: [obj(txb, args.person), pure(txb, args.agent, `address`)],
  });
}

export interface RemoveObjectsFromAgentArgs {
  person: ObjectArg;
  agent: string | TransactionArgument;
  objects: Array<ObjectId | TransactionArgument> | TransactionArgument;
}

export function removeObjectsFromAgent(
  txb: TransactionBlock,
  args: RemoveObjectsFromAgentArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::person_helper::remove_objects_from_agent`,
    arguments: [
      obj(txb, args.person),
      pure(txb, args.agent, `address`),
      pure(txb, args.objects, `vector<0x2::object::ID>`),
    ],
  });
}
