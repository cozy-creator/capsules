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

export interface TransferArgs {
  uid: ObjectArg;
  newOwner: string | TransactionArgument;
  auth: ObjectArg;
}

export function transfer(txb: TransactionBlock, args: TransferArgs) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::org_transfer::transfer`,
    arguments: [
      obj(txb, args.uid),
      pure(txb, args.newOwner, `address`),
      obj(txb, args.auth),
    ],
  });
}

export interface TransferToObjectArgs {
  uid: ObjectArg;
  obj: GenericArg;
  auth: ObjectArg;
}

export function transferToObject(
  txb: TransactionBlock,
  typeArg: Type,
  args: TransferToObjectArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::org_transfer::transfer_to_object`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.uid),
      generic(txb, `${typeArg}`, args.obj),
      obj(txb, args.auth),
    ],
  });
}

export interface TransferToTypeArgs {
  uid: ObjectArg;
  auth: ObjectArg;
}

export function transferToType(
  txb: TransactionBlock,
  typeArg: Type,
  args: TransferToTypeArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::org_transfer::transfer_to_type`,
    typeArguments: [typeArg],
    arguments: [obj(txb, args.uid), obj(txb, args.auth)],
  });
}
