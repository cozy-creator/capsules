import { PUBLISHED_AT } from "..";
import { ObjectArg, Type, obj, pure } from "../../_framework/util";
import { TransactionArgument, TransactionBlock } from "@mysten/sui.js";

export function destroyEmpty(
  txb: TransactionBlock,
  typeArg: Type,
  queue: ObjectArg,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::queue::destroy_empty`,
    typeArguments: [typeArg],
    arguments: [obj(txb, queue)],
  });
}

export function new_(txb: TransactionBlock, typeArg: Type) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::queue::new`,
    typeArguments: [typeArg],
    arguments: [],
  });
}

export function destroy(
  txb: TransactionBlock,
  typeArg: Type,
  queue: ObjectArg,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::queue::destroy`,
    typeArguments: [typeArg],
    arguments: [obj(txb, queue)],
  });
}

export interface WithdrawArgs {
  queue: ObjectArg;
  addr: string | TransactionArgument;
}

export function withdraw(
  txb: TransactionBlock,
  typeArg: Type,
  args: WithdrawArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::queue::withdraw`,
    typeArguments: [typeArg],
    arguments: [obj(txb, args.queue), pure(txb, args.addr, `address`)],
  });
}

export interface BurnInputWithdrawOutputArgs {
  qA: ObjectArg;
  qS: ObjectArg;
  assetSize: bigint | TransactionArgument;
  shareSize: bigint | TransactionArgument;
  supply: ObjectArg;
}

export function burnInputWithdrawOutput(
  txb: TransactionBlock,
  typeArgs: [Type, Type],
  args: BurnInputWithdrawOutputArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::queue::burn_input_withdraw_output`,
    typeArguments: typeArgs,
    arguments: [
      obj(txb, args.qA),
      obj(txb, args.qS),
      pure(txb, args.assetSize, `u64`),
      pure(txb, args.shareSize, `u64`),
      obj(txb, args.supply),
    ],
  });
}

export interface CancelDepositArgs {
  queue: ObjectArg;
  addr: string | TransactionArgument;
}

export function cancelDeposit(
  txb: TransactionBlock,
  typeArg: Type,
  args: CancelDepositArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::queue::cancel_deposit`,
    typeArguments: [typeArg],
    arguments: [obj(txb, args.queue), pure(txb, args.addr, `address`)],
  });
}

export interface DepositArgs {
  queue: ObjectArg;
  addr: string | TransactionArgument;
  balance: ObjectArg;
}

export function deposit(
  txb: TransactionBlock,
  typeArg: Type,
  args: DepositArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::queue::deposit`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.queue),
      pure(txb, args.addr, `address`),
      obj(txb, args.balance),
    ],
  });
}

export interface DepositInputMintOutputArgs {
  qA: ObjectArg;
  qS: ObjectArg;
  assetSize: bigint | TransactionArgument;
  shareSize: bigint | TransactionArgument;
  supply: ObjectArg;
}

export function depositInputMintOutput(
  txb: TransactionBlock,
  typeArgs: [Type, Type],
  args: DepositInputMintOutputArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::queue::deposit_input_mint_output`,
    typeArguments: typeArgs,
    arguments: [
      obj(txb, args.qA),
      obj(txb, args.qS),
      pure(txb, args.assetSize, `u64`),
      pure(txb, args.shareSize, `u64`),
      obj(txb, args.supply),
    ],
  });
}

export interface DirectDepositArgs {
  queue: ObjectArg;
  balance: ObjectArg;
}

export function directDeposit(
  txb: TransactionBlock,
  typeArg: Type,
  args: DirectDepositArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::queue::direct_deposit`,
    typeArguments: [typeArg],
    arguments: [obj(txb, args.queue), obj(txb, args.balance)],
  });
}

export interface DirectWithdrawArgs {
  queue: ObjectArg;
  amount: bigint | TransactionArgument;
}

export function directWithdraw(
  txb: TransactionBlock,
  typeArg: Type,
  args: DirectWithdrawArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::queue::direct_withdraw`,
    typeArguments: [typeArg],
    arguments: [obj(txb, args.queue), pure(txb, args.amount, `u64`)],
  });
}

export interface RatioConversionArgs {
  amount: bigint | TransactionArgument;
  numerator: bigint | TransactionArgument;
  denominator: bigint | TransactionArgument;
}

export function ratioConversion(
  txb: TransactionBlock,
  args: RatioConversionArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::queue::ratio_conversion`,
    arguments: [
      pure(txb, args.amount, `u64`),
      pure(txb, args.numerator, `u64`),
      pure(txb, args.denominator, `u64`),
    ],
  });
}

export function reservesAvailable(
  txb: TransactionBlock,
  typeArg: Type,
  queue: ObjectArg,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::queue::reserves_available`,
    typeArguments: [typeArg],
    arguments: [obj(txb, queue)],
  });
}
