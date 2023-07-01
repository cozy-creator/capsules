import { PUBLISHED_AT } from ".."
import { GenericArg, ObjectArg, Type, generic, obj } from "../../_framework/util"
import { TransactionBlock } from "@mysten/sui.js"

export interface BorrowArgs {
    map: ObjectArg
    key: GenericArg
}

export function borrow(txb: TransactionBlock, typeArgs: [Type, Type], args: BorrowArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::map::borrow`,
        typeArguments: typeArgs,
        arguments: [obj(txb, args.map), generic(txb, `${typeArgs[0]}`, args.key)],
    })
}

export interface BorrowMutArgs {
    map: ObjectArg
    key: GenericArg
}

export function borrowMut(txb: TransactionBlock, typeArgs: [Type, Type], args: BorrowMutArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::map::borrow_mut`,
        typeArguments: typeArgs,
        arguments: [obj(txb, args.map), generic(txb, `${typeArgs[0]}`, args.key)],
    })
}

export function empty(txb: TransactionBlock, typeArgs: [Type, Type]) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::map::empty`,
        typeArguments: typeArgs,
        arguments: [],
    })
}

export function length(txb: TransactionBlock, typeArgs: [Type, Type], map: ObjectArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::map::length`,
        typeArguments: typeArgs,
        arguments: [obj(txb, map)],
    })
}

export interface RemoveArgs {
    map: ObjectArg
    key: GenericArg
}

export function remove(txb: TransactionBlock, typeArgs: [Type, Type], args: RemoveArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::map::remove`,
        typeArguments: typeArgs,
        arguments: [obj(txb, args.map), generic(txb, `${typeArgs[0]}`, args.key)],
    })
}

export function delete_(txb: TransactionBlock, typeArgs: [Type, Type], map: ObjectArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::map::delete`,
        typeArguments: typeArgs,
        arguments: [obj(txb, map)],
    })
}

export interface AddArgs {
    map: ObjectArg
    key: GenericArg
    value: GenericArg
}

export function add(txb: TransactionBlock, typeArgs: [Type, Type], args: AddArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::map::add`,
        typeArguments: typeArgs,
        arguments: [
            obj(txb, args.map),
            generic(txb, `${typeArgs[0]}`, args.key),
            generic(txb, `${typeArgs[1]}`, args.value),
        ],
    })
}

export interface Exists_Args {
    map: ObjectArg
    key: GenericArg
}

export function exists_(txb: TransactionBlock, typeArgs: [Type, Type], args: Exists_Args) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::map::exists_`,
        typeArguments: typeArgs,
        arguments: [obj(txb, args.map), generic(txb, `${typeArgs[0]}`, args.key)],
    })
}

export function intoKeys(txb: TransactionBlock, typeArgs: [Type, Type], map: ObjectArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::map::into_keys`,
        typeArguments: typeArgs,
        arguments: [obj(txb, map)],
    })
}

export interface NextArgs {
    map: ObjectArg
    iter: ObjectArg
}

export function next(txb: TransactionBlock, typeArgs: [Type, Type], args: NextArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::map::next`,
        typeArguments: typeArgs,
        arguments: [obj(txb, args.map), obj(txb, args.iter)],
    })
}

export interface AddToIndexArgs {
    map: ObjectArg
    key: GenericArg
}

export function addToIndex(txb: TransactionBlock, typeArgs: [Type, Type], args: AddToIndexArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::map::add_to_index`,
        typeArguments: typeArgs,
        arguments: [obj(txb, args.map), generic(txb, `${typeArgs[0]}`, args.key)],
    })
}

export function deleteEmpty(txb: TransactionBlock, typeArgs: [Type, Type], map: ObjectArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::map::delete_empty`,
        typeArguments: typeArgs,
        arguments: [obj(txb, map)],
    })
}

export function iter(txb: TransactionBlock, typeArgs: [Type, Type], map: ObjectArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::map::iter`,
        typeArguments: typeArgs,
        arguments: [obj(txb, map)],
    })
}

export interface RemoveFromIndexArgs {
    map: ObjectArg
    key: GenericArg
}

export function removeFromIndex(
    txb: TransactionBlock,
    typeArgs: [Type, Type],
    args: RemoveFromIndexArgs
) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::map::remove_from_index`,
        typeArguments: typeArgs,
        arguments: [obj(txb, args.map), generic(txb, `${typeArgs[0]}`, args.key)],
    })
}
