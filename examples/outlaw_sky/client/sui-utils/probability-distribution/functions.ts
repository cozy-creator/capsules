import { PUBLISHED_AT } from ".."
import { ObjectArg, obj, pure } from "../../_framework/util"
import { TransactionArgument, TransactionBlock } from "@mysten/sui.js"

export interface ExponentialArgs {
    lambda: bigint | TransactionArgument
    min: bigint | TransactionArgument
    max: bigint | TransactionArgument
    weightedHigh: boolean | TransactionArgument
}

export function exponential(txb: TransactionBlock, args: ExponentialArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::probability_distribution::exponential`,
        arguments: [
            pure(txb, args.lambda, `u64`),
            pure(txb, args.min, `u64`),
            pure(txb, args.max, `u64`),
            pure(txb, args.weightedHigh, `bool`),
        ],
    })
}

export interface NormalArgs {
    mean: bigint | TransactionArgument
    stdDev: bigint | TransactionArgument
    min: bigint | TransactionArgument
    max: bigint | TransactionArgument
}

export function normal(txb: TransactionBlock, args: NormalArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::probability_distribution::normal`,
        arguments: [
            pure(txb, args.mean, `u64`),
            pure(txb, args.stdDev, `u64`),
            pure(txb, args.min, `u64`),
            pure(txb, args.max, `u64`),
        ],
    })
}

export function sampleFromDistribution(txb: TransactionBlock, curve: ObjectArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::probability_distribution::sample_from_distribution`,
        arguments: [obj(txb, curve)],
    })
}
