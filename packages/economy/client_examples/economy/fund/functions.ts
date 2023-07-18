import { PUBLISHED_AT } from "..";
import {
  GenericArg,
  ObjectArg,
  Type,
  generic,
  obj,
  option,
  pure,
} from "../../_framework/util";
import { TransactionArgument, TransactionBlock } from "@mysten/sui.js";

export interface DestroyArgs {
  fund: ObjectArg;
  auth: ObjectArg;
}

export function destroy(
  txb: TransactionBlock,
  typeArgs: [Type, Type],
  args: DestroyArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::fund::destroy`,
    typeArguments: typeArgs,
    arguments: [obj(txb, args.fund), obj(txb, args.auth)],
  });
}

export interface CreateArgs {
  otw: GenericArg;
  decimals: number | TransactionArgument;
  symbol: Array<number | TransactionArgument> | TransactionArgument;
  name: Array<number | TransactionArgument> | TransactionArgument;
  description: Array<number | TransactionArgument> | TransactionArgument;
  iconUrl: ObjectArg | TransactionArgument | null;
}

export function create(
  txb: TransactionBlock,
  typeArgs: [Type, Type],
  args: CreateArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::fund::create`,
    typeArguments: typeArgs,
    arguments: [
      generic(txb, `${typeArgs[0]}`, args.otw),
      pure(txb, args.decimals, `u8`),
      pure(txb, args.symbol, `vector<u8>`),
      pure(txb, args.name, `vector<u8>`),
      pure(txb, args.description, `vector<u8>`),
      option(txb, `0x2::url::Url`, args.iconUrl),
    ],
  });
}

export interface ReturnAndShareArgs {
  fund: ObjectArg;
  owner: string | TransactionArgument;
}

export function returnAndShare(
  txb: TransactionBlock,
  typeArgs: [Type, Type],
  args: ReturnAndShareArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::fund::return_and_share`,
    typeArguments: typeArgs,
    arguments: [obj(txb, args.fund), pure(txb, args.owner, `address`)],
  });
}

export function reservesAvailable(
  txb: TransactionBlock,
  typeArgs: [Type, Type],
  fund: ObjectArg,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::fund::reserves_available`,
    typeArguments: typeArgs,
    arguments: [obj(txb, fund)],
  });
}

export interface AssetToSharesArgs {
  fund: ObjectArg;
  asset: bigint | TransactionArgument;
}

export function assetToShares(
  txb: TransactionBlock,
  typeArgs: [Type, Type],
  args: AssetToSharesArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::fund::asset_to_shares`,
    typeArguments: typeArgs,
    arguments: [obj(txb, args.fund), pure(txb, args.asset, `u64`)],
  });
}

export interface CancelPurchaseArgs {
  fund: ObjectArg;
  addr: string | TransactionArgument;
  auth: ObjectArg;
}

export function cancelPurchase(
  txb: TransactionBlock,
  typeArgs: [Type, Type],
  args: CancelPurchaseArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::fund::cancel_purchase`,
    typeArguments: typeArgs,
    arguments: [
      obj(txb, args.fund),
      pure(txb, args.addr, `address`),
      obj(txb, args.auth),
    ],
  });
}

export interface CancelRedeemArgs {
  fund: ObjectArg;
  addr: string | TransactionArgument;
  auth: ObjectArg;
}

export function cancelRedeem(
  txb: TransactionBlock,
  typeArgs: [Type, Type],
  args: CancelRedeemArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::fund::cancel_redeem`,
    typeArguments: typeArgs,
    arguments: [
      obj(txb, args.fund),
      pure(txb, args.addr, `address`),
      obj(txb, args.auth),
    ],
  });
}

export interface DepositAsManagerArgs {
  fund: ObjectArg;
  balance: ObjectArg;
  auth: ObjectArg;
}

export function depositAsManager(
  txb: TransactionBlock,
  typeArgs: [Type, Type],
  args: DepositAsManagerArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::fund::deposit_as_manager`,
    typeArguments: typeArgs,
    arguments: [
      obj(txb, args.fund),
      obj(txb, args.balance),
      obj(txb, args.auth),
    ],
  });
}

export interface InstantPurchaseArgs {
  fund: ObjectArg;
  asset: ObjectArg;
  auth: ObjectArg;
}

export function instantPurchase(
  txb: TransactionBlock,
  typeArgs: [Type, Type],
  args: InstantPurchaseArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::fund::instant_purchase`,
    typeArguments: typeArgs,
    arguments: [obj(txb, args.fund), obj(txb, args.asset), obj(txb, args.auth)],
  });
}

export interface InstantPurchaseResultArgs {
  fund: ObjectArg;
  asset: bigint | TransactionArgument;
}

export function instantPurchaseResult(
  txb: TransactionBlock,
  typeArgs: [Type, Type],
  args: InstantPurchaseResultArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::fund::instant_purchase_result`,
    typeArguments: typeArgs,
    arguments: [obj(txb, args.fund), pure(txb, args.asset, `u64`)],
  });
}

export interface InstantRedeemArgs {
  fund: ObjectArg;
  shares: ObjectArg;
  auth: ObjectArg;
}

export function instantRedeem(
  txb: TransactionBlock,
  typeArgs: [Type, Type],
  args: InstantRedeemArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::fund::instant_redeem`,
    typeArguments: typeArgs,
    arguments: [
      obj(txb, args.fund),
      obj(txb, args.shares),
      obj(txb, args.auth),
    ],
  });
}

export interface InstantRedeemResultArgs {
  fund: ObjectArg;
  shares: bigint | TransactionArgument;
}

export function instantRedeemResult(
  txb: TransactionBlock,
  typeArgs: [Type, Type],
  args: InstantRedeemResultArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::fund::instant_redeem_result`,
    typeArguments: typeArgs,
    arguments: [obj(txb, args.fund), pure(txb, args.shares, `u64`)],
  });
}

export interface ProcessOrdersArgs {
  fund: ObjectArg;
  auth: ObjectArg;
}

export function processOrders(
  txb: TransactionBlock,
  typeArgs: [Type, Type],
  args: ProcessOrdersArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::fund::process_orders`,
    typeArguments: typeArgs,
    arguments: [obj(txb, args.fund), obj(txb, args.auth)],
  });
}

export interface QueuePurchaseArgs {
  fund: ObjectArg;
  addr: string | TransactionArgument;
  asset: ObjectArg;
  auth: ObjectArg;
}

export function queuePurchase(
  txb: TransactionBlock,
  typeArgs: [Type, Type],
  args: QueuePurchaseArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::fund::queue_purchase`,
    typeArguments: typeArgs,
    arguments: [
      obj(txb, args.fund),
      pure(txb, args.addr, `address`),
      obj(txb, args.asset),
      obj(txb, args.auth),
    ],
  });
}

export interface QueueRedeemArgs {
  fund: ObjectArg;
  addr: string | TransactionArgument;
  shares: ObjectArg;
  auth: ObjectArg;
}

export function queueRedeem(
  txb: TransactionBlock,
  typeArgs: [Type, Type],
  args: QueueRedeemArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::fund::queue_redeem`,
    typeArguments: typeArgs,
    arguments: [
      obj(txb, args.fund),
      pure(txb, args.addr, `address`),
      obj(txb, args.shares),
      obj(txb, args.auth),
    ],
  });
}

export interface SharesToAssetArgs {
  fund: ObjectArg;
  shares: bigint | TransactionArgument;
}

export function sharesToAsset(
  txb: TransactionBlock,
  typeArgs: [Type, Type],
  args: SharesToAssetArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::fund::shares_to_asset`,
    typeArguments: typeArgs,
    arguments: [obj(txb, args.fund), pure(txb, args.shares, `u64`)],
  });
}

export interface UpdateConfigArgs {
  fund: ObjectArg;
  publicPurchase: boolean | TransactionArgument;
  publicRedeems: boolean | TransactionArgument;
  instantPurchase: boolean | TransactionArgument;
  instantRedeem: boolean | TransactionArgument;
  auth: ObjectArg;
}

export function updateConfig(
  txb: TransactionBlock,
  typeArgs: [Type, Type],
  args: UpdateConfigArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::fund::update_config`,
    typeArguments: typeArgs,
    arguments: [
      obj(txb, args.fund),
      pure(txb, args.publicPurchase, `bool`),
      pure(txb, args.publicRedeems, `bool`),
      pure(txb, args.instantPurchase, `bool`),
      pure(txb, args.instantRedeem, `bool`),
      obj(txb, args.auth),
    ],
  });
}

export interface UpdateNetAssetsArgs {
  fund: ObjectArg;
  netAssets: bigint | TransactionArgument;
  auth: ObjectArg;
}

export function updateNetAssets(
  txb: TransactionBlock,
  typeArgs: [Type, Type],
  args: UpdateNetAssetsArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::fund::update_net_assets`,
    typeArguments: typeArgs,
    arguments: [
      obj(txb, args.fund),
      pure(txb, args.netAssets, `u64`),
      obj(txb, args.auth),
    ],
  });
}

export interface WithdrawAsManagerArgs {
  fund: ObjectArg;
  amount: bigint | TransactionArgument;
  auth: ObjectArg;
}

export function withdrawAsManager(
  txb: TransactionBlock,
  typeArgs: [Type, Type],
  args: WithdrawAsManagerArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::fund::withdraw_as_manager`,
    typeArguments: typeArgs,
    arguments: [
      obj(txb, args.fund),
      pure(txb, args.amount, `u64`),
      obj(txb, args.auth),
    ],
  });
}
