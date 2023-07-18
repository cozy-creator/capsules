import { PUBLISHED_AT } from "..";
import { ObjectArg, Type, obj, option, pure } from "../../_framework/util";
import {
  ObjectId,
  TransactionArgument,
  TransactionBlock,
} from "@mysten/sui.js";

export interface ReturnAndShareArgs {
  offer: ObjectArg;
  owner: string | TransactionArgument;
}

export function returnAndShare(
  txb: TransactionBlock,
  typeArg: Type,
  args: ReturnAndShareArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::offer::return_and_share`,
    typeArguments: [typeArg],
    arguments: [obj(txb, args.offer), pure(txb, args.owner, `address`)],
  });
}

export function cancel(txb: TransactionBlock) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::offer::cancel`,
    arguments: [],
  });
}

export function cancel_(txb: TransactionBlock) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::offer::cancel_`,
    arguments: [],
  });
}

export function createOffer_(txb: TransactionBlock) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::offer::create_offer_`,
    arguments: [],
  });
}

export function isTypeOffer(
  txb: TransactionBlock,
  typeArg: Type,
  offer: ObjectArg,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::offer::is_type_offer`,
    typeArguments: [typeArg],
    arguments: [obj(txb, offer)],
  });
}

export interface IsValidArgs {
  offer: ObjectArg;
  clock: ObjectArg;
}

export function isValid(
  txb: TransactionBlock,
  typeArg: Type,
  args: IsValidArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::offer::is_valid`,
    typeArguments: [typeArg],
    arguments: [obj(txb, args.offer), obj(txb, args.clock)],
  });
}

export interface MakeOfferArgs {
  account: ObjectArg;
  sendTo: string | TransactionArgument;
  forId: ObjectId | TransactionArgument | TransactionArgument | null;
  forType: ObjectArg | TransactionArgument | null;
  amountEach: bigint | TransactionArgument;
  quantity: number | TransactionArgument;
  durationMs: bigint | TransactionArgument;
  clock: ObjectArg;
  registry: ObjectArg;
  auth: ObjectArg;
}

export function makeOffer(
  txb: TransactionBlock,
  typeArg: Type,
  args: MakeOfferArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::offer::make_offer`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.account),
      pure(txb, args.sendTo, `address`),
      pure(txb, args.forId, `0x1::option::Option<0x2::object::ID>`),
      option(
        txb,
        `0x6adaf7f9c1f7ae68b96dc85f5b069f4a6aabc748d8d741184ca5479fb4466bae::struct_tag::StructTag`,
        args.forType,
      ),
      pure(txb, args.amountEach, `u64`),
      pure(txb, args.quantity, `u8`),
      pure(txb, args.durationMs, `u64`),
      obj(txb, args.clock),
      obj(txb, args.registry),
      obj(txb, args.auth),
    ],
  });
}

export function objectOfferInfo(
  txb: TransactionBlock,
  typeArg: Type,
  offer: ObjectArg,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::offer::object_offer_info`,
    typeArguments: [typeArg],
    arguments: [obj(txb, offer)],
  });
}

export interface TakeOfferArgs {
  offer: ObjectArg;
  offerAccount: ObjectArg;
  takerAccount: ObjectArg;
  item: ObjectArg;
  clock: ObjectArg;
  registry: ObjectArg;
  auth: ObjectArg;
}

export function takeOffer(
  txb: TransactionBlock,
  typeArg: Type,
  args: TakeOfferArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::offer::take_offer`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.offer),
      obj(txb, args.offerAccount),
      obj(txb, args.takerAccount),
      obj(txb, args.item),
      obj(txb, args.clock),
      obj(txb, args.registry),
      obj(txb, args.auth),
    ],
  });
}

export interface TakeOffer_Args {
  offer: ObjectArg;
  offerAccount: ObjectArg;
  takerAccount: ObjectArg;
  item: ObjectArg;
  clock: ObjectArg;
  registry: ObjectArg;
  auth: ObjectArg;
}

export function takeOffer_(
  txb: TransactionBlock,
  typeArg: Type,
  args: TakeOffer_Args,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::offer::take_offer_`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.offer),
      obj(txb, args.offerAccount),
      obj(txb, args.takerAccount),
      obj(txb, args.item),
      obj(txb, args.clock),
      obj(txb, args.registry),
      obj(txb, args.auth),
    ],
  });
}

export function typeOfferInfo(
  txb: TransactionBlock,
  typeArg: Type,
  offer: ObjectArg,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::offer::type_offer_info`,
    typeArguments: [typeArg],
    arguments: [obj(txb, offer)],
  });
}
