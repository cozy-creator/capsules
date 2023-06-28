import { PUBLISHED_AT } from ".."
import { ObjectArg, obj, pure } from "../../_framework/util"
import { TransactionArgument, TransactionBlock } from "@mysten/sui.js"

export function create(txb: TransactionBlock) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::demo_factory::create`,
        arguments: [],
    })
}

export function create_(txb: TransactionBlock) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::demo_factory::create_`,
        arguments: [],
    })
}

export function selectRandom(
    txb: TransactionBlock,
    itemList: Array<Array<number | TransactionArgument> | TransactionArgument> | TransactionArgument
) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::demo_factory::select_random`,
        arguments: [pure(txb, itemList, `vector<vector<u8>>`)],
    })
}

export function view(txb: TransactionBlock, outlaw: ObjectArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::demo_factory::view`,
        arguments: [obj(txb, outlaw)],
    })
}
