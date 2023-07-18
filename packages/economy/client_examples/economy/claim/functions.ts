import { PUBLISHED_AT } from "..";
import { ObjectArg, Type, obj, pure } from "../../_framework/util";
import { TransactionArgument, TransactionBlock } from "@mysten/sui.js";

export interface DestroyArgs {
  claim: ObjectArg;
  account: ObjectArg;
}

export function destroy(
  txb: TransactionBlock,
  typeArg: Type,
  args: DestroyArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::claim::destroy`,
    typeArguments: [typeArg],
    arguments: [obj(txb, args.claim), obj(txb, args.account)],
  });
}

export interface CreateArgs {
  account: ObjectArg;
  amount: bigint | TransactionArgument;
  durationMs: bigint | TransactionArgument;
  clock: ObjectArg;
  registry: ObjectArg;
  auth: ObjectArg;
}

export function create(txb: TransactionBlock, typeArg: Type, args: CreateArgs) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::claim::create`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.account),
      pure(txb, args.amount, `u64`),
      pure(txb, args.durationMs, `u64`),
      obj(txb, args.clock),
      obj(txb, args.registry),
      obj(txb, args.auth),
    ],
  });
}

export function info(txb: TransactionBlock, typeArg: Type, claim: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::claim::info`,
    typeArguments: [typeArg],
    arguments: [obj(txb, claim)],
  });
}

export interface RedeemClaimArgs {
  claim: ObjectArg;
  from: ObjectArg;
  to: ObjectArg;
  amount: bigint | TransactionArgument;
  clock: ObjectArg;
  registry: ObjectArg;
}

export function redeemClaim(
  txb: TransactionBlock,
  typeArg: Type,
  args: RedeemClaimArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::claim::redeem_claim`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.claim),
      obj(txb, args.from),
      obj(txb, args.to),
      pure(txb, args.amount, `u64`),
      obj(txb, args.clock),
      obj(txb, args.registry),
    ],
  });
}

export interface RedeemEntireClaimArgs {
  claim: ObjectArg;
  from: ObjectArg;
  to: ObjectArg;
  clock: ObjectArg;
  registry: ObjectArg;
}

export function redeemEntireClaim(
  txb: TransactionBlock,
  typeArg: Type,
  args: RedeemEntireClaimArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::claim::redeem_entire_claim`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.claim),
      obj(txb, args.from),
      obj(txb, args.to),
      obj(txb, args.clock),
      obj(txb, args.registry),
    ],
  });
}
