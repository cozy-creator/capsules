import { PUBLISHED_AT } from ".."
import { ObjectArg, Type, obj, vector } from "../../_framework/util"
import { TransactionArgument, TransactionBlock } from "@mysten/sui.js"

export interface ContainsArgs {
    types: Array<ObjectArg> | TransactionArgument
    type: ObjectArg
}

export function contains(txb: TransactionBlock, args: ContainsArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::struct_tag::contains`,
        arguments: [
            vector(
                txb,
                `0xfbf59d4ea15bc2da870cd74991503ae3c504bb108061ba5d7270fd0bb0be00b2::struct_tag::StructTag`,
                args.types
            ),
            obj(txb, args.type),
        ],
    })
}

export function get(txb: TransactionBlock, typeArg: Type) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::struct_tag::get`,
        typeArguments: [typeArg],
        arguments: [],
    })
}

export function intoString(txb: TransactionBlock, type: ObjectArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::struct_tag::into_string`,
        arguments: [obj(txb, type)],
    })
}

export function moduleName(txb: TransactionBlock, type: ObjectArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::struct_tag::module_name`,
        arguments: [obj(txb, type)],
    })
}

export function structName(txb: TransactionBlock, type: ObjectArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::struct_tag::struct_name`,
        arguments: [obj(txb, type)],
    })
}

export interface IsSameModuleArgs {
    type1: ObjectArg
    type2: ObjectArg
}

export function isSameModule(txb: TransactionBlock, args: IsSameModuleArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::struct_tag::is_same_module`,
        arguments: [obj(txb, args.type1), obj(txb, args.type2)],
    })
}

export interface IsSameTypeArgs {
    type1: ObjectArg
    type2: ObjectArg
}

export function isSameType(txb: TransactionBlock, args: IsSameTypeArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::struct_tag::is_same_type`,
        arguments: [obj(txb, args.type1), obj(txb, args.type2)],
    })
}

export function packageId(txb: TransactionBlock, type: ObjectArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::struct_tag::package_id`,
        arguments: [obj(txb, type)],
    })
}

export function generics(txb: TransactionBlock, type: ObjectArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::struct_tag::generics`,
        arguments: [obj(txb, type)],
    })
}

export function getAbstract(txb: TransactionBlock, typeArg: Type) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::struct_tag::get_abstract`,
        typeArguments: [typeArg],
        arguments: [],
    })
}

export interface IsSameAbstractTypeArgs {
    type1: ObjectArg
    type2: ObjectArg
}

export function isSameAbstractType(txb: TransactionBlock, args: IsSameAbstractTypeArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::struct_tag::is_same_abstract_type`,
        arguments: [obj(txb, args.type1), obj(txb, args.type2)],
    })
}

export interface MatchArgs {
    type1: ObjectArg
    type2: ObjectArg
}

export function match(txb: TransactionBlock, args: MatchArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::struct_tag::match`,
        arguments: [obj(txb, args.type1), obj(txb, args.type2)],
    })
}
