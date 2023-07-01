import { PUBLISHED_AT } from ".."
import { ObjectArg, obj, pure } from "../../_framework/util"
import { TransactionArgument, TransactionBlock } from "@mysten/sui.js"

export interface CreateArgs {
    data: Array<Array<number | TransactionArgument> | TransactionArgument> | TransactionArgument
    fields: Array<Array<string | TransactionArgument> | TransactionArgument> | TransactionArgument
    owner: string | TransactionArgument
    auth: ObjectArg
}

export function create(txb: TransactionBlock, args: CreateArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::warship::create`,
        arguments: [
            pure(txb, args.data, `vector<vector<u8>>`),
            pure(txb, args.fields, `vector<vector<0x1::string::String>>`),
            pure(txb, args.owner, `address`),
            obj(txb, args.auth),
        ],
    })
}

export interface RenameArgs {
    warship: ObjectArg
    newName: string | TransactionArgument
    auth: ObjectArg
}

export function rename(txb: TransactionBlock, args: RenameArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::warship::rename`,
        arguments: [
            obj(txb, args.warship),
            pure(txb, args.newName, `0x1::string::String`),
            obj(txb, args.auth),
        ],
    })
}

export interface ChangeSizeArgs {
    warship: ObjectArg
    newSize: bigint | TransactionArgument
    auth: ObjectArg
}

export function changeSize(txb: TransactionBlock, args: ChangeSizeArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::warship::change_size`,
        arguments: [obj(txb, args.warship), pure(txb, args.newSize, `u64`), obj(txb, args.auth)],
    })
}

export interface ChangeStrengthArgs {
    warship: ObjectArg
    newStrength: bigint | TransactionArgument
    auth: ObjectArg
}

export function changeStrength(txb: TransactionBlock, args: ChangeStrengthArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::warship::change_strength`,
        arguments: [
            obj(txb, args.warship),
            pure(txb, args.newStrength, `u64`),
            obj(txb, args.auth),
        ],
    })
}
