import { PUBLISHED_AT } from ".."
import { ObjectArg, obj, pure } from "../../_framework/util"
import { ObjectId, TransactionArgument, TransactionBlock } from "@mysten/sui.js"

export function uid(txb: TransactionBlock, outlaw: ObjectArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::outlaw_sky::uid`,
        arguments: [obj(txb, outlaw)],
    })
}

export interface CreateArgs {
    data: Array<Array<number | TransactionArgument> | TransactionArgument> | TransactionArgument
    fields: Array<Array<string | TransactionArgument> | TransactionArgument> | TransactionArgument
    owner: string | TransactionArgument
    auth: ObjectArg
}

export function create(txb: TransactionBlock, args: CreateArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::outlaw_sky::create`,
        arguments: [
            pure(txb, args.data, `vector<vector<u8>>`),
            pure(txb, args.fields, `vector<vector<0x1::string::String>>`),
            pure(txb, args.owner, `address`),
            obj(txb, args.auth),
        ],
    })
}

export interface UidMutArgs {
    outlaw: ObjectArg
    auth: ObjectArg
}

export function uidMut(txb: TransactionBlock, args: UidMutArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::outlaw_sky::uid_mut`,
        arguments: [obj(txb, args.outlaw), obj(txb, args.auth)],
    })
}

export interface ViewAllArgs {
    outlaw: ObjectArg
    namespace: ObjectId | TransactionArgument | TransactionArgument | null
}

export function viewAll(txb: TransactionBlock, args: ViewAllArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::outlaw_sky::view_all`,
        arguments: [
            obj(txb, args.outlaw),
            pure(txb, args.namespace, `0x1::option::Option<0x2::object::ID>`),
        ],
    })
}

export interface AddAttributeArgs {
    outlaw: ObjectArg
    key: string | TransactionArgument
    value: string | TransactionArgument
    auth: ObjectArg
}

export function addAttribute(txb: TransactionBlock, args: AddAttributeArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::outlaw_sky::add_attribute`,
        arguments: [
            obj(txb, args.outlaw),
            pure(txb, args.key, `0x1::string::String`),
            pure(txb, args.value, `0x1::string::String`),
            obj(txb, args.auth),
        ],
    })
}

export interface IncrementPowerLevelArgs {
    outlaw: ObjectArg
    auth: ObjectArg
}

export function incrementPowerLevel(txb: TransactionBlock, args: IncrementPowerLevelArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::outlaw_sky::increment_power_level`,
        arguments: [obj(txb, args.outlaw), obj(txb, args.auth)],
    })
}

export interface IncrementPowerLevel2Args {
    outlaw: ObjectArg
    auth: ObjectArg
}

export function incrementPowerLevel2(txb: TransactionBlock, args: IncrementPowerLevel2Args) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::outlaw_sky::increment_power_level_2`,
        arguments: [obj(txb, args.outlaw), obj(txb, args.auth)],
    })
}

export function init(txb: TransactionBlock, genesis: ObjectArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::outlaw_sky::init`,
        arguments: [obj(txb, genesis)],
    })
}

export function loadDispenser(txb: TransactionBlock) {
    return txb.moveCall({ target: `${PUBLISHED_AT}::outlaw_sky::load_dispenser`, arguments: [] })
}

export interface RemoveAttributeArgs {
    outlaw: ObjectArg
    key: string | TransactionArgument
    auth: ObjectArg
}

export function removeAttribute(txb: TransactionBlock, args: RemoveAttributeArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::outlaw_sky::remove_attribute`,
        arguments: [
            obj(txb, args.outlaw),
            pure(txb, args.key, `0x1::string::String`),
            obj(txb, args.auth),
        ],
    })
}

export interface RenameArgs {
    outlaw: ObjectArg
    newName: string | TransactionArgument
    auth: ObjectArg
}

export function rename(txb: TransactionBlock, args: RenameArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::outlaw_sky::rename`,
        arguments: [
            obj(txb, args.outlaw),
            pure(txb, args.newName, `0x1::string::String`),
            obj(txb, args.auth),
        ],
    })
}
