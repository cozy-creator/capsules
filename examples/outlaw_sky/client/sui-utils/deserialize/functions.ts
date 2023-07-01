import { PUBLISHED_AT } from ".."
import { pure } from "../../_framework/util"
import { TransactionArgument, TransactionBlock } from "@mysten/sui.js"

export interface Address_Args {
    bytes: Array<number | TransactionArgument> | TransactionArgument
    start: bigint | TransactionArgument
}

export function address_(txb: TransactionBlock, args: Address_Args) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::deserialize::address_`,
        arguments: [pure(txb, args.bytes, `vector<u8>`), pure(txb, args.start, `u64`)],
    })
}

export interface Bool_Args {
    bytes: Array<number | TransactionArgument> | TransactionArgument
    start: bigint | TransactionArgument
}

export function bool_(txb: TransactionBlock, args: Bool_Args) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::deserialize::bool_`,
        arguments: [pure(txb, args.bytes, `vector<u8>`), pure(txb, args.start, `u64`)],
    })
}

export interface Id_Args {
    bytes: Array<number | TransactionArgument> | TransactionArgument
    start: bigint | TransactionArgument
}

export function id_(txb: TransactionBlock, args: Id_Args) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::deserialize::id_`,
        arguments: [pure(txb, args.bytes, `vector<u8>`), pure(txb, args.start, `u64`)],
    })
}

export interface String_Args {
    bytes: Array<number | TransactionArgument> | TransactionArgument
    start: bigint | TransactionArgument
}

export function string_(txb: TransactionBlock, args: String_Args) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::deserialize::string_`,
        arguments: [pure(txb, args.bytes, `vector<u8>`), pure(txb, args.start, `u64`)],
    })
}

export interface U128_Args {
    bytes: Array<number | TransactionArgument> | TransactionArgument
    start: bigint | TransactionArgument
}

export function u128_(txb: TransactionBlock, args: U128_Args) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::deserialize::u128_`,
        arguments: [pure(txb, args.bytes, `vector<u8>`), pure(txb, args.start, `u64`)],
    })
}

export interface U16_Args {
    bytes: Array<number | TransactionArgument> | TransactionArgument
    start: bigint | TransactionArgument
}

export function u16_(txb: TransactionBlock, args: U16_Args) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::deserialize::u16_`,
        arguments: [pure(txb, args.bytes, `vector<u8>`), pure(txb, args.start, `u64`)],
    })
}

export interface U256_Args {
    bytes: Array<number | TransactionArgument> | TransactionArgument
    start: bigint | TransactionArgument
}

export function u256_(txb: TransactionBlock, args: U256_Args) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::deserialize::u256_`,
        arguments: [pure(txb, args.bytes, `vector<u8>`), pure(txb, args.start, `u64`)],
    })
}

export interface U32_Args {
    bytes: Array<number | TransactionArgument> | TransactionArgument
    start: bigint | TransactionArgument
}

export function u32_(txb: TransactionBlock, args: U32_Args) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::deserialize::u32_`,
        arguments: [pure(txb, args.bytes, `vector<u8>`), pure(txb, args.start, `u64`)],
    })
}

export interface U64_Args {
    bytes: Array<number | TransactionArgument> | TransactionArgument
    start: bigint | TransactionArgument
}

export function u64_(txb: TransactionBlock, args: U64_Args) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::deserialize::u64_`,
        arguments: [pure(txb, args.bytes, `vector<u8>`), pure(txb, args.start, `u64`)],
    })
}

export interface Url_Args {
    bytes: Array<number | TransactionArgument> | TransactionArgument
    start: bigint | TransactionArgument
}

export function url_(txb: TransactionBlock, args: Url_Args) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::deserialize::url_`,
        arguments: [pure(txb, args.bytes, `vector<u8>`), pure(txb, args.start, `u64`)],
    })
}

export interface VecAddressArgs {
    bytes: Array<number | TransactionArgument> | TransactionArgument
    start: bigint | TransactionArgument
}

export function vecAddress(txb: TransactionBlock, args: VecAddressArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::deserialize::vec_address`,
        arguments: [pure(txb, args.bytes, `vector<u8>`), pure(txb, args.start, `u64`)],
    })
}

export interface VecBoolArgs {
    bytes: Array<number | TransactionArgument> | TransactionArgument
    start: bigint | TransactionArgument
}

export function vecBool(txb: TransactionBlock, args: VecBoolArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::deserialize::vec_bool`,
        arguments: [pure(txb, args.bytes, `vector<u8>`), pure(txb, args.start, `u64`)],
    })
}

export interface VecIdArgs {
    bytes: Array<number | TransactionArgument> | TransactionArgument
    start: bigint | TransactionArgument
}

export function vecId(txb: TransactionBlock, args: VecIdArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::deserialize::vec_id`,
        arguments: [pure(txb, args.bytes, `vector<u8>`), pure(txb, args.start, `u64`)],
    })
}

export interface VecMapStringStringArgs {
    bytes: Array<number | TransactionArgument> | TransactionArgument
    start: bigint | TransactionArgument
}

export function vecMapStringString(txb: TransactionBlock, args: VecMapStringStringArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::deserialize::vec_map_string_string`,
        arguments: [pure(txb, args.bytes, `vector<u8>`), pure(txb, args.start, `u64`)],
    })
}

export interface VecStringArgs {
    bytes: Array<number | TransactionArgument> | TransactionArgument
    start: bigint | TransactionArgument
}

export function vecString(txb: TransactionBlock, args: VecStringArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::deserialize::vec_string`,
        arguments: [pure(txb, args.bytes, `vector<u8>`), pure(txb, args.start, `u64`)],
    })
}

export interface VecU128Args {
    bytes: Array<number | TransactionArgument> | TransactionArgument
    start: bigint | TransactionArgument
}

export function vecU128(txb: TransactionBlock, args: VecU128Args) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::deserialize::vec_u128`,
        arguments: [pure(txb, args.bytes, `vector<u8>`), pure(txb, args.start, `u64`)],
    })
}

export interface VecU16Args {
    bytes: Array<number | TransactionArgument> | TransactionArgument
    start: bigint | TransactionArgument
}

export function vecU16(txb: TransactionBlock, args: VecU16Args) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::deserialize::vec_u16`,
        arguments: [pure(txb, args.bytes, `vector<u8>`), pure(txb, args.start, `u64`)],
    })
}

export interface VecU256Args {
    bytes: Array<number | TransactionArgument> | TransactionArgument
    start: bigint | TransactionArgument
}

export function vecU256(txb: TransactionBlock, args: VecU256Args) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::deserialize::vec_u256`,
        arguments: [pure(txb, args.bytes, `vector<u8>`), pure(txb, args.start, `u64`)],
    })
}

export interface VecU32Args {
    bytes: Array<number | TransactionArgument> | TransactionArgument
    start: bigint | TransactionArgument
}

export function vecU32(txb: TransactionBlock, args: VecU32Args) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::deserialize::vec_u32`,
        arguments: [pure(txb, args.bytes, `vector<u8>`), pure(txb, args.start, `u64`)],
    })
}

export interface VecU64Args {
    bytes: Array<number | TransactionArgument> | TransactionArgument
    start: bigint | TransactionArgument
}

export function vecU64(txb: TransactionBlock, args: VecU64Args) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::deserialize::vec_u64`,
        arguments: [pure(txb, args.bytes, `vector<u8>`), pure(txb, args.start, `u64`)],
    })
}

export interface VecU8Args {
    bytes: Array<number | TransactionArgument> | TransactionArgument
    start: bigint | TransactionArgument
}

export function vecU8(txb: TransactionBlock, args: VecU8Args) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::deserialize::vec_u8`,
        arguments: [pure(txb, args.bytes, `vector<u8>`), pure(txb, args.start, `u64`)],
    })
}

export interface VecUrlArgs {
    bytes: Array<number | TransactionArgument> | TransactionArgument
    start: bigint | TransactionArgument
}

export function vecUrl(txb: TransactionBlock, args: VecUrlArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::deserialize::vec_url`,
        arguments: [pure(txb, args.bytes, `vector<u8>`), pure(txb, args.start, `u64`)],
    })
}

export interface VecVecMapStringStringArgs {
    bytes: Array<number | TransactionArgument> | TransactionArgument
    start: bigint | TransactionArgument
}

export function vecVecMapStringString(txb: TransactionBlock, args: VecVecMapStringStringArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::deserialize::vec_vec_map_string_string`,
        arguments: [pure(txb, args.bytes, `vector<u8>`), pure(txb, args.start, `u64`)],
    })
}

export interface VecVecU8Args {
    bytes: Array<number | TransactionArgument> | TransactionArgument
    start: bigint | TransactionArgument
}

export function vecVecU8(txb: TransactionBlock, args: VecVecU8Args) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::deserialize::vec_vec_u8`,
        arguments: [pure(txb, args.bytes, `vector<u8>`), pure(txb, args.start, `u64`)],
    })
}
