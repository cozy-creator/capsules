import { PUBLISHED_AT } from "..";
import {
  GenericArg,
  ObjectArg,
  Type,
  generic,
  obj,
  pure,
} from "../../_framework/util";
import {
  ObjectId,
  TransactionArgument,
  TransactionBlock,
} from "@mysten/sui.js";

export function uid(txb: TransactionBlock, publisher: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::publish_receipt::uid`,
    arguments: [obj(txb, publisher)],
  });
}

export function destroy(txb: TransactionBlock, publisher: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::publish_receipt::destroy`,
    arguments: [obj(txb, publisher)],
  });
}

export function claim(
  txb: TransactionBlock,
  typeArg: Type,
  genesis: GenericArg,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::publish_receipt::claim`,
    typeArguments: [typeArg],
    arguments: [generic(txb, `${typeArg}`, genesis)],
  });
}

export function uidMut(txb: TransactionBlock, publisher: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::publish_receipt::uid_mut`,
    arguments: [obj(txb, publisher)],
  });
}

export function didPublish(
  txb: TransactionBlock,
  typeArg: Type,
  publisher: ObjectArg,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::publish_receipt::did_publish`,
    typeArguments: [typeArg],
    arguments: [obj(txb, publisher)],
  });
}

export interface DidPublish_Args {
  publisher: ObjectArg;
  id: ObjectId | TransactionArgument;
}

export function didPublish_(txb: TransactionBlock, args: DidPublish_Args) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::publish_receipt::did_publish_`,
    arguments: [
      obj(txb, args.publisher),
      pure(txb, args.id, `0x2::object::ID`),
    ],
  });
}

export function intoPackageId(txb: TransactionBlock, publisher: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::publish_receipt::into_package_id`,
    arguments: [obj(txb, publisher)],
  });
}
