import { PUBLISHED_AT } from ".."
import { GenericArg, ObjectArg, Type, generic, obj, pure } from "../../_framework/util"
import { TransactionArgument, TransactionBlock } from "@mysten/sui.js"

export function borrow(txb: TransactionBlock, typeArg: Type, immutable: ObjectArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::immutable::borrow`,
        typeArguments: [typeArg],
        arguments: [obj(txb, immutable)],
    })
}

export interface Freeze_Args {
    contents: GenericArg
    allowRead: boolean | TransactionArgument
}

export function freeze_(txb: TransactionBlock, typeArg: Type, args: Freeze_Args) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::immutable::freeze_`,
        typeArguments: [typeArg],
        arguments: [generic(txb, `${typeArg}`, args.contents), pure(txb, args.allowRead, `bool`)],
    })
}
