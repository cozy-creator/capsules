import { PUBLISHED_AT } from ".."
import { pure } from "../../_framework/util"
import { ObjectId, TransactionArgument, TransactionBlock } from "@mysten/sui.js"

export function empty(txb: TransactionBlock) {
    return txb.moveCall({ target: `${PUBLISHED_AT}::string2::empty`, arguments: [] })
}

export function fromAddress(txb: TransactionBlock, addr: string | TransactionArgument) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::string2::from_address`,
        arguments: [pure(txb, addr, `address`)],
    })
}

export function fromId(txb: TransactionBlock, id: ObjectId | TransactionArgument) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::string2::from_id`,
        arguments: [pure(txb, id, `0x2::object::ID`)],
    })
}

export function intoAddress(txb: TransactionBlock, str: string | TransactionArgument) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::string2::into_address`,
        arguments: [pure(txb, str, `0x1::string::String`)],
    })
}

export function intoId(txb: TransactionBlock, str: string | TransactionArgument) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::string2::into_id`,
        arguments: [pure(txb, str, `0x1::string::String`)],
    })
}
