import { PUBLISHED_AT } from ".."
import { GenericArg, ObjectArg, Type, generic, obj } from "../../_framework/util"
import { TransactionBlock } from "@mysten/sui.js"

export function collapseBalance(txb: TransactionBlock, typeArgs: [Type, Type], table: ObjectArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::linked_table2::collapse_balance`,
        typeArguments: typeArgs,
        arguments: [obj(txb, table)],
    })
}

export interface MergeBalanceArgs {
    table: ObjectArg
    key: GenericArg
    balance: ObjectArg
}

export function mergeBalance(
    txb: TransactionBlock,
    typeArgs: [Type, Type],
    args: MergeBalanceArgs
) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::linked_table2::merge_balance`,
        typeArguments: typeArgs,
        arguments: [
            obj(txb, args.table),
            generic(txb, `${typeArgs[0]}`, args.key),
            obj(txb, args.balance),
        ],
    })
}
