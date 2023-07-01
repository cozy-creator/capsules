import { PUBLISHED_AT } from ".."
import { Type, pure } from "../../_framework/util"
import { TransactionArgument, TransactionBlock } from "@mysten/sui.js"

export function typeName(txb: TransactionBlock, typeArg: Type) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::encode::type_name`,
        typeArguments: [typeArg],
        arguments: [],
    })
}

export function moduleName(txb: TransactionBlock, typeArg: Type) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::encode::module_name`,
        typeArguments: [typeArg],
        arguments: [],
    })
}

export function appendStructName(
    txb: TransactionBlock,
    typeArg: Type,
    structName: string | TransactionArgument
) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::encode::append_struct_name`,
        typeArguments: [typeArg],
        arguments: [pure(txb, structName, `0x1::string::String`)],
    })
}

export interface AppendStructName_Args {
    moduleAddr: string | TransactionArgument
    structName: string | TransactionArgument
}

export function appendStructName_(txb: TransactionBlock, args: AppendStructName_Args) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::encode::append_struct_name_`,
        arguments: [
            pure(txb, args.moduleAddr, `0x1::string::String`),
            pure(txb, args.structName, `0x1::string::String`),
        ],
    })
}

export function decomposeStructName(txb: TransactionBlock, s1: string | TransactionArgument) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::encode::decompose_struct_name`,
        arguments: [pure(txb, s1, `0x1::string::String`)],
    })
}

export function decomposeTypeName(txb: TransactionBlock, s1: string | TransactionArgument) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::encode::decompose_type_name`,
        arguments: [pure(txb, s1, `0x1::string::String`)],
    })
}

export function hasGenerics(txb: TransactionBlock, typeArg: Type) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::encode::has_generics`,
        typeArguments: [typeArg],
        arguments: [],
    })
}

export function isSameModule(txb: TransactionBlock, typeArgs: [Type, Type]) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::encode::is_same_module`,
        typeArguments: typeArgs,
        arguments: [],
    })
}

export function isSameType(txb: TransactionBlock, typeArgs: [Type, Type]) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::encode::is_same_type`,
        typeArguments: typeArgs,
        arguments: [],
    })
}

export function isVector(txb: TransactionBlock, str: string | TransactionArgument) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::encode::is_vector`,
        arguments: [pure(txb, str, `0x1::string::String`)],
    })
}

export function moduleAndStructName(txb: TransactionBlock, typeArg: Type) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::encode::module_and_struct_name`,
        typeArguments: [typeArg],
        arguments: [],
    })
}

export function packageAddr(txb: TransactionBlock, typeArg: Type) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::encode::package_addr`,
        typeArguments: [typeArg],
        arguments: [],
    })
}

export function packageAddr_(txb: TransactionBlock, typeName: string | TransactionArgument) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::encode::package_addr_`,
        arguments: [pure(txb, typeName, `0x1::string::String`)],
    })
}

export function packageId(txb: TransactionBlock, typeArg: Type) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::encode::package_id`,
        typeArguments: [typeArg],
        arguments: [],
    })
}

export function packageId_(txb: TransactionBlock, typeName: string | TransactionArgument) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::encode::package_id_`,
        arguments: [pure(txb, typeName, `0x1::string::String`)],
    })
}

export function packageIdAndModuleName(txb: TransactionBlock, typeArg: Type) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::encode::package_id_and_module_name`,
        typeArguments: [typeArg],
        arguments: [],
    })
}

export function packageIdAndModuleName_(txb: TransactionBlock, s1: string | TransactionArgument) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::encode::package_id_and_module_name_`,
        arguments: [pure(txb, s1, `0x1::string::String`)],
    })
}

export function parseAngleBracket(txb: TransactionBlock, str: string | TransactionArgument) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::encode::parse_angle_bracket`,
        arguments: [pure(txb, str, `0x1::string::String`)],
    })
}

export function parseCommaDelimitedList(txb: TransactionBlock, str: string | TransactionArgument) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::encode::parse_comma_delimited_list`,
        arguments: [pure(txb, str, `0x1::string::String`)],
    })
}

export function parseOption(txb: TransactionBlock, str: string | TransactionArgument) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::encode::parse_option`,
        arguments: [pure(txb, str, `0x1::string::String`)],
    })
}

export function typeIntoAddress(txb: TransactionBlock, typeArg: Type) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::encode::type_into_address`,
        typeArguments: [typeArg],
        arguments: [],
    })
}

export function typeNameDecomposed(txb: TransactionBlock, typeArg: Type) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::encode::type_name_decomposed`,
        typeArguments: [typeArg],
        arguments: [],
    })
}

export function typeStringIntoAddress(txb: TransactionBlock, type: string | TransactionArgument) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::encode::type_string_into_address`,
        arguments: [pure(txb, type, `0x1::string::String`)],
    })
}
