import { PUBLISHED_AT } from ".."
import { ObjectArg, obj, pure } from "../../_framework/util"
import { TransactionArgument, TransactionBlock } from "@mysten/sui.js"

export interface UpdateArgs {
    outlaw: ObjectArg
    data: Array<Array<number | TransactionArgument> | TransactionArgument> | TransactionArgument
    fields: Array<Array<string | TransactionArgument> | TransactionArgument> | TransactionArgument
    auth: ObjectArg
}

export function update(txb: TransactionBlock, args: UpdateArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::outlaw_sky_helper::update`,
        arguments: [
            obj(txb, args.outlaw),
            pure(txb, args.data, `vector<vector<u8>>`),
            pure(txb, args.fields, `vector<vector<0x1::string::String>>`),
            obj(txb, args.auth),
        ],
    })
}

export interface RemoveAllArgs {
    outlaw: ObjectArg
    auth: ObjectArg
}

export function removeAll(txb: TransactionBlock, args: RemoveAllArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::outlaw_sky_helper::remove_all`,
        arguments: [obj(txb, args.outlaw), obj(txb, args.auth)],
    })
}
