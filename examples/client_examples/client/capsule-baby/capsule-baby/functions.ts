import { PUBLISHED_AT } from "..";
import { ObjectArg, obj, pure } from "../../_framework/util";
import { TransactionArgument, TransactionBlock } from "@mysten/sui.js";

export function createBaby(
  txb: TransactionBlock,
  name: string | TransactionArgument
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::capsule_baby::create_baby`,
    arguments: [pure(txb, name, `0x1::string::String`)],
  });
}

export interface CreateBaby_Args {
  name: string | TransactionArgument;
  owner: string | TransactionArgument;
}

export function createBaby_(txb: TransactionBlock, args: CreateBaby_Args) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::capsule_baby::create_baby_`,
    arguments: [
      pure(txb, args.name, `0x1::string::String`),
      pure(txb, args.owner, `address`),
    ],
  });
}

export interface EditBabyNameArgs {
  baby: ObjectArg;
  newName: string | TransactionArgument;
  auth: ObjectArg;
}

export function editBabyName(txb: TransactionBlock, args: EditBabyNameArgs) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::capsule_baby::edit_baby_name`,
    arguments: [
      obj(txb, args.baby),
      pure(txb, args.newName, `0x1::string::String`),
      obj(txb, args.auth),
    ],
  });
}

export function init(txb: TransactionBlock, genesis: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::capsule_baby::init`,
    arguments: [obj(txb, genesis)],
  });
}

export function returnAndShare(txb: TransactionBlock, baby: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::capsule_baby::return_and_share`,
    arguments: [obj(txb, baby)],
  });
}
