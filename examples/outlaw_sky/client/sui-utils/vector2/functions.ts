import { PUBLISHED_AT } from ".."
import { GenericArg, Type, generic, pure, vector } from "../../_framework/util"
import { TransactionArgument, TransactionBlock } from "@mysten/sui.js"

export interface BorrowMutPaddingArgs {
    vec: Array<GenericArg> | TransactionArgument
    index: number | TransactionArgument
    defaultValue: GenericArg
}

export function borrowMutPadding(txb: TransactionBlock, typeArg: Type, args: BorrowMutPaddingArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::vector2::borrow_mut_padding`,
        typeArguments: [typeArg],
        arguments: [
            vector(txb, `${typeArg}`, args.vec),
            pure(txb, args.index, `u16`),
            generic(txb, `${typeArg}`, args.defaultValue),
        ],
    })
}

export interface IntersectionArgs {
    vec1: Array<GenericArg> | TransactionArgument
    vec2: Array<GenericArg> | TransactionArgument
}

export function intersection(txb: TransactionBlock, typeArg: Type, args: IntersectionArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::vector2::intersection`,
        typeArguments: [typeArg],
        arguments: [vector(txb, `${typeArg}`, args.vec1), vector(txb, `${typeArg}`, args.vec2)],
    })
}

export interface MergeArgs {
    destination: Array<GenericArg> | TransactionArgument
    source: Array<GenericArg> | TransactionArgument
}

export function merge(txb: TransactionBlock, typeArg: Type, args: MergeArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::vector2::merge`,
        typeArguments: [typeArg],
        arguments: [
            vector(txb, `${typeArg}`, args.destination),
            vector(txb, `${typeArg}`, args.source),
        ],
    })
}

export interface Merge_Args {
    destination: Array<GenericArg> | TransactionArgument
    source: Array<GenericArg> | TransactionArgument
}

export function merge_(txb: TransactionBlock, typeArg: Type, args: Merge_Args) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::vector2::merge_`,
        typeArguments: [typeArg],
        arguments: [
            vector(txb, `${typeArg}`, args.destination),
            vector(txb, `${typeArg}`, args.source),
        ],
    })
}

export interface PushBackUniqueArgs {
    self: Array<GenericArg> | TransactionArgument
    item: GenericArg
}

export function pushBackUnique(txb: TransactionBlock, typeArg: Type, args: PushBackUniqueArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::vector2::push_back_unique`,
        typeArguments: [typeArg],
        arguments: [vector(txb, `${typeArg}`, args.self), generic(txb, `${typeArg}`, args.item)],
    })
}

export interface RemoveMaybeArgs {
    vec: Array<GenericArg> | TransactionArgument
    item: GenericArg
}

export function removeMaybe(txb: TransactionBlock, typeArg: Type, args: RemoveMaybeArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::vector2::remove_maybe`,
        typeArguments: [typeArg],
        arguments: [vector(txb, `${typeArg}`, args.vec), generic(txb, `${typeArg}`, args.item)],
    })
}

export interface SliceArgs {
    vec: Array<GenericArg> | TransactionArgument
    start: bigint | TransactionArgument
    end: bigint | TransactionArgument
}

export function slice(txb: TransactionBlock, typeArg: Type, args: SliceArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::vector2::slice`,
        typeArguments: [typeArg],
        arguments: [
            vector(txb, `${typeArg}`, args.vec),
            pure(txb, args.start, `u64`),
            pure(txb, args.end, `u64`),
        ],
    })
}

export interface SliceMutArgs {
    vec: Array<GenericArg> | TransactionArgument
    start: bigint | TransactionArgument
    end: bigint | TransactionArgument
}

export function sliceMut(txb: TransactionBlock, typeArg: Type, args: SliceMutArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::vector2::slice_mut`,
        typeArguments: [typeArg],
        arguments: [
            vector(txb, `${typeArg}`, args.vec),
            pure(txb, args.start, `u64`),
            pure(txb, args.end, `u64`),
        ],
    })
}
