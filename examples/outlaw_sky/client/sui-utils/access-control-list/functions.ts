import { PUBLISHED_AT } from ".."
import { pure } from "../../_framework/util"
import { TransactionArgument, TransactionBlock } from "@mysten/sui.js"

export interface AddRoleArgs {
    acl: number | TransactionArgument
    role: number | TransactionArgument
}

export function addRole(txb: TransactionBlock, args: AddRoleArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::access_control_list::add_role`,
        arguments: [pure(txb, args.acl, `u16`), pure(txb, args.role, `u8`)],
    })
}

export interface AndMergeArgs {
    acl: number | TransactionArgument
    other: number | TransactionArgument
}

export function andMerge(txb: TransactionBlock, args: AndMergeArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::access_control_list::and_merge`,
        arguments: [pure(txb, args.acl, `u16`), pure(txb, args.other, `u16`)],
    })
}

export interface HasRoleArgs {
    acl: number | TransactionArgument
    role: number | TransactionArgument
}

export function hasRole(txb: TransactionBlock, args: HasRoleArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::access_control_list::has_role`,
        arguments: [pure(txb, args.acl, `u16`), pure(txb, args.role, `u8`)],
    })
}

export interface OrMergeArgs {
    acl: number | TransactionArgument
    other: number | TransactionArgument
}

export function orMerge(txb: TransactionBlock, args: OrMergeArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::access_control_list::or_merge`,
        arguments: [pure(txb, args.acl, `u16`), pure(txb, args.other, `u16`)],
    })
}

export interface RemoveRoleArgs {
    acl: number | TransactionArgument
    role: number | TransactionArgument
}

export function removeRole(txb: TransactionBlock, args: RemoveRoleArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::access_control_list::remove_role`,
        arguments: [pure(txb, args.acl, `u16`), pure(txb, args.role, `u8`)],
    })
}
