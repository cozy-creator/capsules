import { PUBLISHED_AT } from ".."
import { GenericArg, ObjectArg, Type, generic, obj, vector } from "../../_framework/util"
import { TransactionArgument, TransactionBlock } from "@mysten/sui.js"

export interface GetWithDefaultArgs {
    self: ObjectArg
    key: GenericArg
    default: GenericArg
}

export function getWithDefault(
    txb: TransactionBlock,
    typeArgs: [Type, Type],
    args: GetWithDefaultArgs
) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::vec_map2::get_with_default`,
        typeArguments: typeArgs,
        arguments: [
            obj(txb, args.self),
            generic(txb, `${typeArgs[0]}`, args.key),
            generic(txb, `${typeArgs[1]}`, args.default),
        ],
    })
}

export interface NewArgs {
    key: GenericArg
    value: GenericArg
}

export function new_(txb: TransactionBlock, typeArgs: [Type, Type], args: NewArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::vec_map2::new`,
        typeArguments: typeArgs,
        arguments: [
            generic(txb, `${typeArgs[0]}`, args.key),
            generic(txb, `${typeArgs[1]}`, args.value),
        ],
    })
}

export interface SetArgs {
    self: ObjectArg
    key: GenericArg
    value: GenericArg
}

export function set(txb: TransactionBlock, typeArgs: [Type, Type], args: SetArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::vec_map2::set`,
        typeArguments: typeArgs,
        arguments: [
            obj(txb, args.self),
            generic(txb, `${typeArgs[0]}`, args.key),
            generic(txb, `${typeArgs[1]}`, args.value),
        ],
    })
}

export interface CreateArgs {
    keys: Array<GenericArg> | TransactionArgument
    values: Array<GenericArg> | TransactionArgument
}

export function create(txb: TransactionBlock, typeArgs: [Type, Type], args: CreateArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::vec_map2::create`,
        typeArguments: typeArgs,
        arguments: [
            vector(txb, `${typeArgs[0]}`, args.keys),
            vector(txb, `${typeArgs[1]}`, args.values),
        ],
    })
}

export interface MergeArgs {
    self: ObjectArg
    other: ObjectArg
}

export function merge(txb: TransactionBlock, typeArgs: [Type, Type], args: MergeArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::vec_map2::merge`,
        typeArguments: typeArgs,
        arguments: [obj(txb, args.self), obj(txb, args.other)],
    })
}

export interface RemoveMaybeArgs {
    self: ObjectArg
    key: GenericArg
}

export function removeMaybe(txb: TransactionBlock, typeArgs: [Type, Type], args: RemoveMaybeArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::vec_map2::remove_maybe`,
        typeArguments: typeArgs,
        arguments: [obj(txb, args.self), generic(txb, `${typeArgs[0]}`, args.key)],
    })
}

export interface BorrowMutFillArgs {
    self: ObjectArg
    key: GenericArg
    defaultValue: GenericArg
}

export function borrowMutFill(
    txb: TransactionBlock,
    typeArgs: [Type, Type],
    args: BorrowMutFillArgs
) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::vec_map2::borrow_mut_fill`,
        typeArguments: typeArgs,
        arguments: [
            obj(txb, args.self),
            generic(txb, `${typeArgs[0]}`, args.key),
            generic(txb, `${typeArgs[1]}`, args.defaultValue),
        ],
    })
}

export interface GetManyArgs {
    self: ObjectArg
    keys: Array<GenericArg> | TransactionArgument
}

export function getMany(txb: TransactionBlock, typeArgs: [Type, Type], args: GetManyArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::vec_map2::get_many`,
        typeArguments: typeArgs,
        arguments: [obj(txb, args.self), vector(txb, `${typeArgs[0]}`, args.keys)],
    })
}

export interface GetMaybeArgs {
    self: ObjectArg
    key: GenericArg
}

export function getMaybe(txb: TransactionBlock, typeArgs: [Type, Type], args: GetMaybeArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::vec_map2::get_maybe`,
        typeArguments: typeArgs,
        arguments: [obj(txb, args.self), generic(txb, `${typeArgs[0]}`, args.key)],
    })
}

export interface InsertMaybeArgs {
    self: ObjectArg
    key: GenericArg
    value: GenericArg
}

export function insertMaybe(txb: TransactionBlock, typeArgs: [Type, Type], args: InsertMaybeArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::vec_map2::insert_maybe`,
        typeArguments: typeArgs,
        arguments: [
            obj(txb, args.self),
            generic(txb, `${typeArgs[0]}`, args.key),
            generic(txb, `${typeArgs[1]}`, args.value),
        ],
    })
}

export interface MatchStructTagMaybeArgs {
    self: ObjectArg
    structTag: ObjectArg
}

export function matchStructTagMaybe(
    txb: TransactionBlock,
    typeArg: Type,
    args: MatchStructTagMaybeArgs
) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::vec_map2::match_struct_tag_maybe`,
        typeArguments: [typeArg],
        arguments: [obj(txb, args.self), obj(txb, args.structTag)],
    })
}

export interface MergeValueArgs {
    self: ObjectArg
    key: GenericArg
    value: GenericArg
}

export function mergeValue(txb: TransactionBlock, typeArgs: [Type, Type], args: MergeValueArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::vec_map2::merge_value`,
        typeArguments: typeArgs,
        arguments: [
            obj(txb, args.self),
            generic(txb, `${typeArgs[0]}`, args.key),
            generic(txb, `${typeArgs[1]}`, args.value),
        ],
    })
}

export interface RemoveEntriesWithValueArgs {
    self: ObjectArg
    value: GenericArg
}

export function removeEntriesWithValue(
    txb: TransactionBlock,
    typeArgs: [Type, Type],
    args: RemoveEntriesWithValueArgs
) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::vec_map2::remove_entries_with_value`,
        typeArguments: typeArgs,
        arguments: [obj(txb, args.self), generic(txb, `${typeArgs[1]}`, args.value)],
    })
}
