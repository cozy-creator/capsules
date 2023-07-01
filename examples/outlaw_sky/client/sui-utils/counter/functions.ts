import { PUBLISHED_AT } from ".."
import { GenericArg, ObjectArg, Type, generic, obj } from "../../_framework/util"
import { TransactionBlock } from "@mysten/sui.js"

export function new_(txb: TransactionBlock, typeArg: Type, w: GenericArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::counter::new`,
        typeArguments: [typeArg],
        arguments: [generic(txb, `${typeArg}`, w)],
    })
}

export interface DecrementArgs {
    self: ObjectArg
    w: GenericArg
}

export function decrement(txb: TransactionBlock, typeArg: Type, args: DecrementArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::counter::decrement`,
        typeArguments: [typeArg],
        arguments: [obj(txb, args.self), generic(txb, `${typeArg}`, args.w)],
    })
}

export interface IncrementArgs {
    self: ObjectArg
    w: GenericArg
}

export function increment(txb: TransactionBlock, typeArg: Type, args: IncrementArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::counter::increment`,
        typeArguments: [typeArg],
        arguments: [obj(txb, args.self), generic(txb, `${typeArg}`, args.w)],
    })
}

export function new__(txb: TransactionBlock, typeArg: Type, w: GenericArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::counter::new_`,
        typeArguments: [typeArg],
        arguments: [generic(txb, `${typeArg}`, w)],
    })
}
