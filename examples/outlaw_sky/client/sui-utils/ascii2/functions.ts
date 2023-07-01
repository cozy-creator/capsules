import { PUBLISHED_AT } from ".."
import { pure } from "../../_framework/util"
import { TransactionArgument, TransactionBlock } from "@mysten/sui.js"

export interface IndexOfArgs {
    s: string | TransactionArgument
    r: string | TransactionArgument
}

export function indexOf(txb: TransactionBlock, args: IndexOfArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::ascii2::index_of`,
        arguments: [
            pure(txb, args.s, `0x1::ascii::String`),
            pure(txb, args.r, `0x1::ascii::String`),
        ],
    })
}

export interface AppendArgs {
    s: string | TransactionArgument
    r: string | TransactionArgument
}

export function append(txb: TransactionBlock, args: AppendArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::ascii2::append`,
        arguments: [
            pure(txb, args.s, `0x1::ascii::String`),
            pure(txb, args.r, `0x1::ascii::String`),
        ],
    })
}

export function empty(txb: TransactionBlock) {
    return txb.moveCall({ target: `${PUBLISHED_AT}::ascii2::empty`, arguments: [] })
}

export interface SubStringArgs {
    s: string | TransactionArgument
    i: bigint | TransactionArgument
    j: bigint | TransactionArgument
}

export function subString(txb: TransactionBlock, args: SubStringArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::ascii2::sub_string`,
        arguments: [
            pure(txb, args.s, `0x1::ascii::String`),
            pure(txb, args.i, `u64`),
            pure(txb, args.j, `u64`),
        ],
    })
}

export function addrIntoString(txb: TransactionBlock, addr: string | TransactionArgument) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::ascii2::addr_into_string`,
        arguments: [pure(txb, addr, `address`)],
    })
}

export function asciiBytesIntoId(
    txb: TransactionBlock,
    asciiBytes: Array<number | TransactionArgument> | TransactionArgument
) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::ascii2::ascii_bytes_into_id`,
        arguments: [pure(txb, asciiBytes, `vector<u8>`)],
    })
}

export function asciiIntoId(txb: TransactionBlock, str: string | TransactionArgument) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::ascii2::ascii_into_id`,
        arguments: [pure(txb, str, `0x1::ascii::String`)],
    })
}

export function asciiToU8(txb: TransactionBlock, char: number | TransactionArgument) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::ascii2::ascii_to_u8`,
        arguments: [pure(txb, char, `u8`)],
    })
}

export function bytesToStrings(
    txb: TransactionBlock,
    bytes: Array<Array<number | TransactionArgument> | TransactionArgument> | TransactionArgument
) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::ascii2::bytes_to_strings`,
        arguments: [pure(txb, bytes, `vector<vector<u8>>`)],
    })
}

export interface IntoCharArgs {
    string: string | TransactionArgument
    i: bigint | TransactionArgument
}

export function intoChar(txb: TransactionBlock, args: IntoCharArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::ascii2::into_char`,
        arguments: [pure(txb, args.string, `0x1::ascii::String`), pure(txb, args.i, `u64`)],
    })
}

export function toLowerCase(txb: TransactionBlock, string: string | TransactionArgument) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::ascii2::to_lower_case`,
        arguments: [pure(txb, string, `0x1::ascii::String`)],
    })
}

export function toUpperCase(txb: TransactionBlock, string: string | TransactionArgument) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::ascii2::to_upper_case`,
        arguments: [pure(txb, string, `0x1::ascii::String`)],
    })
}

export function u8ToAscii(txb: TransactionBlock, num: number | TransactionArgument) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::ascii2::u8_to_ascii`,
        arguments: [pure(txb, num, `u8`)],
    })
}

export function vecBytesToVecStrings(
    txb: TransactionBlock,
    bytes:
        | Array<
              Array<Array<number | TransactionArgument> | TransactionArgument> | TransactionArgument
          >
        | TransactionArgument
) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::ascii2::vec_bytes_to_vec_strings`,
        arguments: [pure(txb, bytes, `vector<vector<vector<u8>>>`)],
    })
}
