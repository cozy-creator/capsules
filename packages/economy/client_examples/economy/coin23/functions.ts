import { PUBLISHED_AT } from "..";
import { ObjectArg, Type, obj, pure } from "../../_framework/util";
import { TransactionArgument, TransactionBlock } from "@mysten/sui.js";

export interface DestroyEmptyArgs {
  account: ObjectArg;
  auth: ObjectArg;
}

export function destroyEmpty(
  txb: TransactionBlock,
  typeArg: Type,
  args: DestroyEmptyArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::destroy_empty`,
    typeArguments: [typeArg],
    arguments: [obj(txb, args.account), obj(txb, args.auth)],
  });
}

export function uid(txb: TransactionBlock, typeArg: Type, account: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::uid`,
    typeArguments: [typeArg],
    arguments: [obj(txb, account)],
  });
}

export interface DestroyArgs {
  account: ObjectArg;
  registry: ObjectArg;
  auth: ObjectArg;
}

export function destroy(
  txb: TransactionBlock,
  typeArg: Type,
  args: DestroyArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::destroy`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.account),
      obj(txb, args.registry),
      obj(txb, args.auth),
    ],
  });
}

export interface TransferArgs {
  from: ObjectArg;
  to: ObjectArg;
  amount: bigint | TransactionArgument;
  registry: ObjectArg;
  auth: ObjectArg;
}

export function transfer(
  txb: TransactionBlock,
  typeArg: Type,
  args: TransferArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::transfer`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.from),
      obj(txb, args.to),
      pure(txb, args.amount, `u64`),
      obj(txb, args.registry),
      obj(txb, args.auth),
    ],
  });
}

export function create(txb: TransactionBlock, typeArg: Type) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::create`,
    typeArguments: [typeArg],
    arguments: [],
  });
}

export function uidMut(
  txb: TransactionBlock,
  typeArg: Type,
  account: ObjectArg,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::uid_mut`,
    typeArguments: [typeArg],
    arguments: [obj(txb, account)],
  });
}

export function isFrozen(
  txb: TransactionBlock,
  typeArg: Type,
  account: ObjectArg,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::is_frozen`,
    typeArguments: [typeArg],
    arguments: [obj(txb, account)],
  });
}

export interface ReturnAndShareArgs {
  account: ObjectArg;
  owner: string | TransactionArgument;
}

export function returnAndShare(
  txb: TransactionBlock,
  typeArg: Type,
  args: ReturnAndShareArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::return_and_share`,
    typeArguments: [typeArg],
    arguments: [obj(txb, args.account), pure(txb, args.owner, `address`)],
  });
}

export interface AddHoldArgs {
  customer: ObjectArg;
  merchantAddr: string | TransactionArgument;
  amount: bigint | TransactionArgument;
  durationMs: bigint | TransactionArgument;
  clock: ObjectArg;
  registry: ObjectArg;
  auth: ObjectArg;
}

export function addHold(
  txb: TransactionBlock,
  typeArg: Type,
  args: AddHoldArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::add_hold`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.customer),
      pure(txb, args.merchantAddr, `address`),
      pure(txb, args.amount, `u64`),
      pure(txb, args.durationMs, `u64`),
      obj(txb, args.clock),
      obj(txb, args.registry),
      obj(txb, args.auth),
    ],
  });
}

export interface AddHold_Args {
  customer: ObjectArg;
  merchantAddr: string | TransactionArgument;
  amount: bigint | TransactionArgument;
  durationMs: bigint | TransactionArgument;
  clock: ObjectArg;
  registry: ObjectArg;
}

export function addHold_(
  txb: TransactionBlock,
  typeArg: Type,
  args: AddHold_Args,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::add_hold_`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.customer),
      pure(txb, args.merchantAddr, `address`),
      pure(txb, args.amount, `u64`),
      pure(txb, args.durationMs, `u64`),
      obj(txb, args.clock),
      obj(txb, args.registry),
    ],
  });
}

export interface AddRebillArgs {
  customer: ObjectArg;
  merchantAddr: string | TransactionArgument;
  maxAmount: bigint | TransactionArgument;
  refreshCadence: bigint | TransactionArgument;
  clock: ObjectArg;
  registry: ObjectArg;
  auth: ObjectArg;
}

export function addRebill(
  txb: TransactionBlock,
  typeArg: Type,
  args: AddRebillArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::add_rebill`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.customer),
      pure(txb, args.merchantAddr, `address`),
      pure(txb, args.maxAmount, `u64`),
      pure(txb, args.refreshCadence, `u64`),
      obj(txb, args.clock),
      obj(txb, args.registry),
      obj(txb, args.auth),
    ],
  });
}

export function balanceAvailable(
  txb: TransactionBlock,
  typeArg: Type,
  account: ObjectArg,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::balance_available`,
    typeArguments: [typeArg],
    arguments: [obj(txb, account)],
  });
}

export interface CalculateTransferFeeArgs {
  amount: bigint | TransactionArgument;
  registry: ObjectArg;
}

export function calculateTransferFee(
  txb: TransactionBlock,
  typeArg: Type,
  args: CalculateTransferFeeArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::calculate_transfer_fee`,
    typeArguments: [typeArg],
    arguments: [pure(txb, args.amount, `u64`), obj(txb, args.registry)],
  });
}

export interface CancelAllRebillsForMerchantArgs {
  customer: ObjectArg;
  merchantAddr: string | TransactionArgument;
  auth: ObjectArg;
}

export function cancelAllRebillsForMerchant(
  txb: TransactionBlock,
  typeArg: Type,
  args: CancelAllRebillsForMerchantArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::cancel_all_rebills_for_merchant`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.customer),
      pure(txb, args.merchantAddr, `address`),
      obj(txb, args.auth),
    ],
  });
}

export interface CancelRebillArgs {
  customer: ObjectArg;
  merchantAddr: string | TransactionArgument;
  rebillIndex: bigint | TransactionArgument;
  auth: ObjectArg;
}

export function cancelRebill(
  txb: TransactionBlock,
  typeArg: Type,
  args: CancelRebillArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::cancel_rebill`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.customer),
      pure(txb, args.merchantAddr, `address`),
      pure(txb, args.rebillIndex, `u64`),
      obj(txb, args.auth),
    ],
  });
}

export interface ChargeAndRebillArgs {
  customer: ObjectArg;
  merchant: ObjectArg;
  amount: bigint | TransactionArgument;
  rebillCadence: bigint | TransactionArgument;
  clock: ObjectArg;
  registry: ObjectArg;
}

export function chargeAndRebill(
  txb: TransactionBlock,
  typeArg: Type,
  args: ChargeAndRebillArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::charge_and_rebill`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.customer),
      obj(txb, args.merchant),
      pure(txb, args.amount, `u64`),
      pure(txb, args.rebillCadence, `u64`),
      obj(txb, args.clock),
      obj(txb, args.registry),
    ],
  });
}

export interface ChargeAndReleaseHoldArgs {
  customer: ObjectArg;
  merchant: ObjectArg;
  amount: bigint | TransactionArgument;
  organization: ObjectArg;
  clock: ObjectArg;
  registry: ObjectArg;
}

export function chargeAndReleaseHold(
  txb: TransactionBlock,
  typeArg: Type,
  args: ChargeAndReleaseHoldArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::charge_and_release_hold`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.customer),
      obj(txb, args.merchant),
      pure(txb, args.amount, `u64`),
      obj(txb, args.organization),
      obj(txb, args.clock),
      obj(txb, args.registry),
    ],
  });
}

export interface CrankArgs {
  account: ObjectArg;
  clock: ObjectArg;
}

export function crank(txb: TransactionBlock, typeArg: Type, args: CrankArgs) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::crank`,
    typeArguments: [typeArg],
    arguments: [obj(txb, args.account), obj(txb, args.clock)],
  });
}

export interface CrankRebillArgs {
  rebill: ObjectArg;
  clock: ObjectArg;
}

export function crankRebill(txb: TransactionBlock, args: CrankRebillArgs) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::crank_rebill`,
    arguments: [obj(txb, args.rebill), obj(txb, args.clock)],
  });
}

export function create_(
  txb: TransactionBlock,
  typeArg: Type,
  owner: string | TransactionArgument,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::create_`,
    typeArguments: [typeArg],
    arguments: [pure(txb, owner, `address`)],
  });
}

export function destroyCurrency(txb: TransactionBlock) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::destroy_currency`,
    arguments: [],
  });
}

export interface DisableCreatorWithdrawArgs {
  registry: ObjectArg;
  auth: ObjectArg;
}

export function disableCreatorWithdraw(
  txb: TransactionBlock,
  typeArg: Type,
  args: DisableCreatorWithdrawArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::disable_creator_withdraw`,
    typeArguments: [typeArg],
    arguments: [obj(txb, args.registry), obj(txb, args.auth)],
  });
}

export interface DisableFreezeAbilityArgs {
  registry: ObjectArg;
  auth: ObjectArg;
}

export function disableFreezeAbility(
  txb: TransactionBlock,
  typeArg: Type,
  args: DisableFreezeAbilityArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::disable_freeze_ability`,
    typeArguments: [typeArg],
    arguments: [obj(txb, args.registry), obj(txb, args.auth)],
  });
}

export function exportAuths(
  txb: TransactionBlock,
  typeArg: Type,
  registry: ObjectArg,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::export_auths`,
    typeArguments: [typeArg],
    arguments: [obj(txb, registry)],
  });
}

export interface ExportToBalanceArgs {
  account: ObjectArg;
  registry: ObjectArg;
  amount: bigint | TransactionArgument;
  auth: ObjectArg;
}

export function exportToBalance(
  txb: TransactionBlock,
  typeArg: Type,
  args: ExportToBalanceArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::export_to_balance`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.account),
      obj(txb, args.registry),
      pure(txb, args.amount, `u64`),
      obj(txb, args.auth),
    ],
  });
}

export interface ExportToCoinArgs {
  account: ObjectArg;
  registry: ObjectArg;
  amount: bigint | TransactionArgument;
  auth: ObjectArg;
}

export function exportToCoin(
  txb: TransactionBlock,
  typeArg: Type,
  args: ExportToCoinArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::export_to_coin`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.account),
      obj(txb, args.registry),
      pure(txb, args.amount, `u64`),
      obj(txb, args.auth),
    ],
  });
}

export interface Freeze_Args {
  account: ObjectArg;
  registry: ObjectArg;
  auth: ObjectArg;
}

export function freeze_(
  txb: TransactionBlock,
  typeArg: Type,
  args: Freeze_Args,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::freeze_`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.account),
      obj(txb, args.registry),
      obj(txb, args.auth),
    ],
  });
}

export function grantCurrency(txb: TransactionBlock) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::grant_currency`,
    arguments: [],
  });
}

export interface ImportFromBalanceArgs {
  account: ObjectArg;
  balance: ObjectArg;
}

export function importFromBalance(
  txb: TransactionBlock,
  typeArg: Type,
  args: ImportFromBalanceArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::import_from_balance`,
    typeArguments: [typeArg],
    arguments: [obj(txb, args.account), obj(txb, args.balance)],
  });
}

export interface ImportFromCoinArgs {
  account: ObjectArg;
  coin: ObjectArg;
}

export function importFromCoin(
  txb: TransactionBlock,
  typeArg: Type,
  args: ImportFromCoinArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::import_from_coin`,
    typeArguments: [typeArg],
    arguments: [obj(txb, args.account), obj(txb, args.coin)],
  });
}

export function init(txb: TransactionBlock, otw: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::init`,
    arguments: [obj(txb, otw)],
  });
}

export function inspectCreatorCurrencyControls(
  txb: TransactionBlock,
  typeArg: Type,
  registry: ObjectArg,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::inspect_creator_currency_controls`,
    typeArguments: [typeArg],
    arguments: [obj(txb, registry)],
  });
}

export interface InspectHoldArgs {
  account: ObjectArg;
  merchantAddr: string | TransactionArgument;
}

export function inspectHold(
  txb: TransactionBlock,
  typeArg: Type,
  args: InspectHoldArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::inspect_hold`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.account),
      pure(txb, args.merchantAddr, `address`),
    ],
  });
}

export function inspectRebill(txb: TransactionBlock, rebill: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::inspect_rebill`,
    arguments: [obj(txb, rebill)],
  });
}

export function isCurrencyExportable(
  txb: TransactionBlock,
  typeArg: Type,
  registry: ObjectArg,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::is_currency_exportable`,
    typeArguments: [typeArg],
    arguments: [obj(txb, registry)],
  });
}

export function isCurrencyTransferable(
  txb: TransactionBlock,
  typeArg: Type,
  registry: ObjectArg,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::is_currency_transferable`,
    typeArguments: [typeArg],
    arguments: [obj(txb, registry)],
  });
}

export interface IsValidExportArgs {
  account: ObjectArg;
  registry: ObjectArg;
  auth: ObjectArg;
}

export function isValidExport(
  txb: TransactionBlock,
  typeArg: Type,
  args: IsValidExportArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::is_valid_export`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.account),
      obj(txb, args.registry),
      obj(txb, args.auth),
    ],
  });
}

export interface IsValidTransferArgs {
  account: ObjectArg;
  registry: ObjectArg;
  auth: ObjectArg;
}

export function isValidTransfer(
  txb: TransactionBlock,
  typeArg: Type,
  args: IsValidTransferArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::is_valid_transfer`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.account),
      obj(txb, args.registry),
      obj(txb, args.auth),
    ],
  });
}

export function merchantsWithHeldFunds(
  txb: TransactionBlock,
  typeArg: Type,
  account: ObjectArg,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::merchants_with_held_funds`,
    typeArguments: [typeArg],
    arguments: [obj(txb, account)],
  });
}

export function merchantsWithRebills(
  txb: TransactionBlock,
  typeArg: Type,
  account: ObjectArg,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::merchants_with_rebills`,
    typeArguments: [typeArg],
    arguments: [obj(txb, account)],
  });
}

export interface PayTransferFeeArgs {
  account: ObjectArg;
  amount: bigint | TransactionArgument;
  registry: ObjectArg;
}

export function payTransferFee(
  txb: TransactionBlock,
  typeArg: Type,
  args: PayTransferFeeArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::pay_transfer_fee`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.account),
      pure(txb, args.amount, `u64`),
      obj(txb, args.registry),
    ],
  });
}

export interface RebillsForMerchantArgs {
  account: ObjectArg;
  merchantAddr: string | TransactionArgument;
}

export function rebillsForMerchant(
  txb: TransactionBlock,
  typeArg: Type,
  args: RebillsForMerchantArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::rebills_for_merchant`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.account),
      pure(txb, args.merchantAddr, `address`),
    ],
  });
}

export interface RegisterCurrencyArgs {
  registry: ObjectArg;
  creatorCanWithdraw: boolean | TransactionArgument;
  creatorCanFreeze: boolean | TransactionArgument;
  userTransferEnum: number | TransactionArgument;
  transferFeeBps: bigint | TransactionArgument | TransactionArgument | null;
  transferFeeAddr: string | TransactionArgument | TransactionArgument | null;
  exportAuths: Array<string | TransactionArgument> | TransactionArgument;
  auth: ObjectArg;
}

export function registerCurrency(
  txb: TransactionBlock,
  typeArg: Type,
  args: RegisterCurrencyArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::register_currency`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.registry),
      pure(txb, args.creatorCanWithdraw, `bool`),
      pure(txb, args.creatorCanFreeze, `bool`),
      pure(txb, args.userTransferEnum, `u8`),
      pure(txb, args.transferFeeBps, `0x1::option::Option<u64>`),
      pure(txb, args.transferFeeAddr, `0x1::option::Option<address>`),
      pure(txb, args.exportAuths, `vector<address>`),
      obj(txb, args.auth),
    ],
  });
}

export interface ReleaseHeldFundsArgs {
  customer: ObjectArg;
  merchantAddr: string | TransactionArgument;
  auth: ObjectArg;
}

export function releaseHeldFunds(
  txb: TransactionBlock,
  typeArg: Type,
  args: ReleaseHeldFundsArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::release_held_funds`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.customer),
      pure(txb, args.merchantAddr, `address`),
      obj(txb, args.auth),
    ],
  });
}

export interface ReleaseHoldInternalArgs {
  account: ObjectArg;
  merchantAddr: string | TransactionArgument;
}

export function releaseHoldInternal(
  txb: TransactionBlock,
  typeArg: Type,
  args: ReleaseHoldInternalArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::release_hold_internal`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.account),
      pure(txb, args.merchantAddr, `address`),
    ],
  });
}

export interface SetTransferFeeArgs {
  registry: ObjectArg;
  transferFeeBps: bigint | TransactionArgument | TransactionArgument | null;
  transferFeeAddr: string | TransactionArgument | TransactionArgument | null;
  auth: ObjectArg;
}

export function setTransferFee(
  txb: TransactionBlock,
  typeArg: Type,
  args: SetTransferFeeArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::set_transfer_fee`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.registry),
      pure(txb, args.transferFeeBps, `0x1::option::Option<u64>`),
      pure(txb, args.transferFeeAddr, `0x1::option::Option<address>`),
      obj(txb, args.auth),
    ],
  });
}

export interface SetTransferPolicyArgs {
  registry: ObjectArg;
  userTransferEnum: number | TransactionArgument;
  exportAuths: Array<string | TransactionArgument> | TransactionArgument;
  auth: ObjectArg;
}

export function setTransferPolicy(
  txb: TransactionBlock,
  typeArg: Type,
  args: SetTransferPolicyArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::set_transfer_policy`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.registry),
      pure(txb, args.userTransferEnum, `u8`),
      pure(txb, args.exportAuths, `vector<address>`),
      obj(txb, args.auth),
    ],
  });
}

export interface TransferFeeStructArgs {
  bps: bigint | TransactionArgument | TransactionArgument | null;
  addr: string | TransactionArgument | TransactionArgument | null;
}

export function transferFeeStruct(
  txb: TransactionBlock,
  args: TransferFeeStructArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::transfer_fee_struct`,
    arguments: [
      pure(txb, args.bps, `0x1::option::Option<u64>`),
      pure(txb, args.addr, `0x1::option::Option<address>`),
    ],
  });
}

export interface UnfreezeArgs {
  account: ObjectArg;
  auth: ObjectArg;
}

export function unfreeze(
  txb: TransactionBlock,
  typeArg: Type,
  args: UnfreezeArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::unfreeze`,
    typeArguments: [typeArg],
    arguments: [obj(txb, args.account), obj(txb, args.auth)],
  });
}

export interface WithdrawFromHeldFundsArgs {
  customer: ObjectArg;
  merchant: ObjectArg;
  amount: bigint | TransactionArgument;
  clock: ObjectArg;
  registry: ObjectArg;
  auth: ObjectArg;
}

export function withdrawFromHeldFunds(
  txb: TransactionBlock,
  typeArg: Type,
  args: WithdrawFromHeldFundsArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::withdraw_from_held_funds`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.customer),
      obj(txb, args.merchant),
      pure(txb, args.amount, `u64`),
      obj(txb, args.clock),
      obj(txb, args.registry),
      obj(txb, args.auth),
    ],
  });
}

export interface WithdrawFromHeldFunds_Args {
  customer: ObjectArg;
  merchant: ObjectArg;
  merchantAddr: string | TransactionArgument;
  amount: bigint | TransactionArgument;
  clock: ObjectArg;
  registry: ObjectArg;
  auth: ObjectArg;
}

export function withdrawFromHeldFunds_(
  txb: TransactionBlock,
  typeArg: Type,
  args: WithdrawFromHeldFunds_Args,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::withdraw_from_held_funds_`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.customer),
      obj(txb, args.merchant),
      pure(txb, args.merchantAddr, `address`),
      pure(txb, args.amount, `u64`),
      obj(txb, args.clock),
      obj(txb, args.registry),
      obj(txb, args.auth),
    ],
  });
}

export interface WithdrawWithRebillArgs {
  customer: ObjectArg;
  merchant: ObjectArg;
  rebillIndex: bigint | TransactionArgument;
  amount: bigint | TransactionArgument;
  clock: ObjectArg;
  registry: ObjectArg;
  auth: ObjectArg;
}

export function withdrawWithRebill(
  txb: TransactionBlock,
  typeArg: Type,
  args: WithdrawWithRebillArgs,
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::coin23::withdraw_with_rebill`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.customer),
      obj(txb, args.merchant),
      pure(txb, args.rebillIndex, `u64`),
      pure(txb, args.amount, `u64`),
      obj(txb, args.clock),
      obj(txb, args.registry),
      obj(txb, args.auth),
    ],
  });
}
