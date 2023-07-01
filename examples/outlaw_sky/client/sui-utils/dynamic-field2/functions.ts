import { PUBLISHED_AT } from ".."
import { GenericArg, ObjectArg, Type, generic, obj } from "../../_framework/util"
import { TransactionBlock } from "@mysten/sui.js"

export interface GetWithDefaultArgs {
    uid: ObjectArg
    key: GenericArg
    default: GenericArg
}

export function getWithDefault(
    txb: TransactionBlock,
    typeArgs: [Type, Type],
    args: GetWithDefaultArgs
) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::dynamic_field2::get_with_default`,
        typeArguments: typeArgs,
        arguments: [
            obj(txb, args.uid),
            generic(txb, `${typeArgs[0]}`, args.key),
            generic(txb, `${typeArgs[1]}`, args.default),
        ],
    })
}

export interface SetArgs {
    uid: ObjectArg
    key: GenericArg
    value: GenericArg
}

export function set(txb: TransactionBlock, typeArgs: [Type, Type], args: SetArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::dynamic_field2::set`,
        typeArguments: typeArgs,
        arguments: [
            obj(txb, args.uid),
            generic(txb, `${typeArgs[0]}`, args.key),
            generic(txb, `${typeArgs[1]}`, args.value),
        ],
    })
}

export interface DropArgs {
    uid: ObjectArg
    key: GenericArg
}

export function drop(txb: TransactionBlock, typeArgs: [Type, Type], args: DropArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::dynamic_field2::drop`,
        typeArguments: typeArgs,
        arguments: [obj(txb, args.uid), generic(txb, `${typeArgs[0]}`, args.key)],
    })
}

export interface BorrowMutFillArgs {
    uid: ObjectArg
    key: GenericArg
    default: GenericArg
}

export function borrowMutFill(
    txb: TransactionBlock,
    typeArgs: [Type, Type],
    args: BorrowMutFillArgs
) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::dynamic_field2::borrow_mut_fill`,
        typeArguments: typeArgs,
        arguments: [
            obj(txb, args.uid),
            generic(txb, `${typeArgs[0]}`, args.key),
            generic(txb, `${typeArgs[1]}`, args.default),
        ],
    })
}

export interface GetMaybeArgs {
    uid: ObjectArg
    key: GenericArg
}

export function getMaybe(txb: TransactionBlock, typeArgs: [Type, Type], args: GetMaybeArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::dynamic_field2::get_maybe`,
        typeArguments: typeArgs,
        arguments: [obj(txb, args.uid), generic(txb, `${typeArgs[0]}`, args.key)],
    })
}
