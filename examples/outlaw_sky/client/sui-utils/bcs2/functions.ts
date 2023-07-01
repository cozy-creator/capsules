import { PUBLISHED_AT } from ".."
import { ObjectArg, obj, pure } from "../../_framework/util"
import { TransactionArgument, TransactionBlock } from "@mysten/sui.js"

export function peelAscii(txb: TransactionBlock, bcs: ObjectArg) {
    return txb.moveCall({ target: `${PUBLISHED_AT}::bcs2::peel_ascii`, arguments: [obj(txb, bcs)] })
}

export function peelId(txb: TransactionBlock, bcs: ObjectArg) {
    return txb.moveCall({ target: `${PUBLISHED_AT}::bcs2::peel_id`, arguments: [obj(txb, bcs)] })
}

export function peelOptionByte(txb: TransactionBlock, bcs: ObjectArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::bcs2::peel_option_byte`,
        arguments: [obj(txb, bcs)],
    })
}

export function peelUtf8(txb: TransactionBlock, bcs: ObjectArg) {
    return txb.moveCall({ target: `${PUBLISHED_AT}::bcs2::peel_utf8`, arguments: [obj(txb, bcs)] })
}

export function peelVecAscii(txb: TransactionBlock, bcs: ObjectArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::bcs2::peel_vec_ascii`,
        arguments: [obj(txb, bcs)],
    })
}

export function peelVecId(txb: TransactionBlock, bcs: ObjectArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::bcs2::peel_vec_id`,
        arguments: [obj(txb, bcs)],
    })
}

export function peelVecMapUtf8(txb: TransactionBlock, bcs: ObjectArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::bcs2::peel_vec_map_utf8`,
        arguments: [obj(txb, bcs)],
    })
}

export function peelVecUtf8(txb: TransactionBlock, bcs: ObjectArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::bcs2::peel_vec_utf8`,
        arguments: [obj(txb, bcs)],
    })
}

export function u64IntoUleb128(txb: TransactionBlock, num: bigint | TransactionArgument) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::bcs2::u64_into_uleb128`,
        arguments: [pure(txb, num, `u64`)],
    })
}

export interface Uleb128LengthArgs {
    data: Array<number | TransactionArgument> | TransactionArgument
    start: bigint | TransactionArgument
}

export function uleb128Length(txb: TransactionBlock, args: Uleb128LengthArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::bcs2::uleb128_length`,
        arguments: [pure(txb, args.data, `vector<u8>`), pure(txb, args.start, `u64`)],
    })
}
