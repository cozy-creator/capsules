import { PUBLISHED_AT } from ".."
import { GenericArg, ObjectArg, Type, generic, obj, vector } from "../../_framework/util"
import { TransactionArgument, TransactionBlock } from "@mysten/sui.js"

export interface ContainsArgs {
    self: ObjectArg
    key: GenericArg
}

export function contains(txb: TransactionBlock, typeArg: Type, args: ContainsArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::vec_set2::contains`,
        typeArguments: [typeArg],
        arguments: [obj(txb, args.self), generic(txb, `${typeArg}`, args.key)],
    })
}

export function empty(txb: TransactionBlock, typeArg: Type) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::vec_set2::empty`,
        typeArguments: [typeArg],
        arguments: [],
    })
}

export function isEmpty(txb: TransactionBlock, typeArg: Type, self: ObjectArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::vec_set2::is_empty`,
        typeArguments: [typeArg],
        arguments: [obj(txb, self)],
    })
}

export interface RemoveArgs {
    self: ObjectArg
    key: GenericArg
}

export function remove(txb: TransactionBlock, typeArg: Type, args: RemoveArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::vec_set2::remove`,
        typeArguments: [typeArg],
        arguments: [obj(txb, args.self), generic(txb, `${typeArg}`, args.key)],
    })
}

export interface AddArgs {
    self: ObjectArg
    key: GenericArg
}

export function add(txb: TransactionBlock, typeArg: Type, args: AddArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::vec_set2::add`,
        typeArguments: [typeArg],
        arguments: [obj(txb, args.self), generic(txb, `${typeArg}`, args.key)],
    })
}

export function size(txb: TransactionBlock, typeArg: Type, self: ObjectArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::vec_set2::size`,
        typeArguments: [typeArg],
        arguments: [obj(txb, self)],
    })
}

export function create(
    txb: TransactionBlock,
    typeArg: Type,
    keys: Array<GenericArg> | TransactionArgument
) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::vec_set2::create`,
        typeArguments: [typeArg],
        arguments: [vector(txb, `${typeArg}`, keys)],
    })
}

export function intoKeys(txb: TransactionBlock, typeArg: Type, self: ObjectArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::vec_set2::into_keys`,
        typeArguments: [typeArg],
        arguments: [obj(txb, self)],
    })
}

export interface GetIndexArgs {
    self: ObjectArg
    key: GenericArg
}

export function getIndex(txb: TransactionBlock, typeArg: Type, args: GetIndexArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::vec_set2::get_index`,
        typeArguments: [typeArg],
        arguments: [obj(txb, args.self), generic(txb, `${typeArg}`, args.key)],
    })
}
