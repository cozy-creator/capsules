import { bcsSource as bcs } from "../../../../_framework/bcs"
import { initLoaderIfNeeded } from "../../../../_framework/init-source"
import { structClassLoaderSource } from "../../../../_framework/loader"
import { FieldsWithTypes, Type, parseTypeName } from "../../../../_framework/util"
import { Encoding } from "@mysten/bcs"

/* ============================== Out =============================== */

bcs.registerStructType(
    "0x5afccfc2e6d32ec3a2066406035dc1494959a66d3c679f8069fe765640d4ceb1::vector2::Out<T>",
    {
        vec: `vector<T>`,
        start: `u64`,
        end: `u64`,
    }
)

export function isOut(type: Type): boolean {
    return type.startsWith(
        "0x5afccfc2e6d32ec3a2066406035dc1494959a66d3c679f8069fe765640d4ceb1::vector2::Out<"
    )
}

export interface OutFields<T> {
    vec: Array<T>
    start: bigint
    end: bigint
}

export class Out<T> {
    static readonly $typeName =
        "0x5afccfc2e6d32ec3a2066406035dc1494959a66d3c679f8069fe765640d4ceb1::vector2::Out"
    static readonly $numTypeParams = 1

    readonly $typeArg: Type

    readonly vec: Array<T>
    readonly start: bigint
    readonly end: bigint

    constructor(typeArg: Type, fields: OutFields<T>) {
        this.$typeArg = typeArg

        this.vec = fields.vec
        this.start = fields.start
        this.end = fields.end
    }

    static fromFields<T>(typeArg: Type, fields: Record<string, any>): Out<T> {
        initLoaderIfNeeded()

        return new Out(typeArg, {
            vec: fields.vec.map((item: any) => structClassLoaderSource.fromFields(typeArg, item)),
            start: BigInt(fields.start),
            end: BigInt(fields.end),
        })
    }

    static fromFieldsWithTypes<T>(item: FieldsWithTypes): Out<T> {
        initLoaderIfNeeded()

        if (!isOut(item.type)) {
            throw new Error("not a Out type")
        }
        const { typeArgs } = parseTypeName(item.type)

        return new Out(typeArgs[0], {
            vec: item.fields.vec.map((item: any) =>
                structClassLoaderSource.fromFieldsWithTypes(typeArgs[0], item)
            ),
            start: BigInt(item.fields.start),
            end: BigInt(item.fields.end),
        })
    }

    static fromBcs<T>(typeArg: Type, data: Uint8Array | string, encoding?: Encoding): Out<T> {
        return Out.fromFields(typeArg, bcs.de([Out.$typeName, typeArg], data, encoding))
    }
}
