import { PUBLISHED_AT } from ".."
import { GenericArg, ObjectArg, Type, generic, obj, pure } from "../../_framework/util"
import { TransactionArgument, TransactionBlock } from "@mysten/sui.js"

export function fromSeed(
    txb: TransactionBlock,
    seed: Array<number | TransactionArgument> | TransactionArgument
) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::rand::from_seed`,
        arguments: [pure(txb, seed, `vector<u8>`)],
    })
}

export function seed(txb: TransactionBlock) {
    return txb.moveCall({ target: `${PUBLISHED_AT}::rand::seed`, arguments: [] })
}

export function rawSeed(txb: TransactionBlock) {
    return txb.moveCall({ target: `${PUBLISHED_AT}::rand::raw_seed`, arguments: [] })
}

export interface RngArgs {
    min: bigint | TransactionArgument
    max: bigint | TransactionArgument
}

export function rng(txb: TransactionBlock, args: RngArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::rand::rng`,
        arguments: [pure(txb, args.min, `u64`), pure(txb, args.max, `u64`)],
    })
}

export interface RngWithClockArgs {
    min: bigint | TransactionArgument
    max: bigint | TransactionArgument
    clock: ObjectArg
}

export function rngWithClock(txb: TransactionBlock, args: RngWithClockArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::rand::rng_with_clock`,
        arguments: [pure(txb, args.min, `u64`), pure(txb, args.max, `u64`), obj(txb, args.clock)],
    })
}

export interface RngWithClockAndCounterArgs {
    w: GenericArg
    min: bigint | TransactionArgument
    max: bigint | TransactionArgument
    clock: ObjectArg
    counter: ObjectArg
}

export function rngWithClockAndCounter(
    txb: TransactionBlock,
    typeArg: Type,
    args: RngWithClockAndCounterArgs
) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::rand::rng_with_clock_and_counter`,
        typeArguments: [typeArg],
        arguments: [
            generic(txb, `${typeArg}`, args.w),
            pure(txb, args.min, `u64`),
            pure(txb, args.max, `u64`),
            obj(txb, args.clock),
            obj(txb, args.counter),
        ],
    })
}

export interface RngWithCounterArgs {
    w: GenericArg
    min: bigint | TransactionArgument
    max: bigint | TransactionArgument
    counter: ObjectArg
}

export function rngWithCounter(txb: TransactionBlock, typeArg: Type, args: RngWithCounterArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::rand::rng_with_counter`,
        typeArguments: [typeArg],
        arguments: [
            generic(txb, `${typeArg}`, args.w),
            pure(txb, args.min, `u64`),
            pure(txb, args.max, `u64`),
            obj(txb, args.counter),
        ],
    })
}

export function seedWithClock(txb: TransactionBlock, clock: ObjectArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::rand::seed_with_clock`,
        arguments: [obj(txb, clock)],
    })
}

export interface SeedWithClockAndCounterArgs {
    w: GenericArg
    clock: ObjectArg
    counter: ObjectArg
}

export function seedWithClockAndCounter(
    txb: TransactionBlock,
    typeArg: Type,
    args: SeedWithClockAndCounterArgs
) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::rand::seed_with_clock_and_counter`,
        typeArguments: [typeArg],
        arguments: [
            generic(txb, `${typeArg}`, args.w),
            obj(txb, args.clock),
            obj(txb, args.counter),
        ],
    })
}

export interface SeedWithCounterArgs {
    w: GenericArg
    counter: ObjectArg
}

export function seedWithCounter(txb: TransactionBlock, typeArg: Type, args: SeedWithCounterArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::rand::seed_with_counter`,
        typeArguments: [typeArg],
        arguments: [generic(txb, `${typeArg}`, args.w), obj(txb, args.counter)],
    })
}
