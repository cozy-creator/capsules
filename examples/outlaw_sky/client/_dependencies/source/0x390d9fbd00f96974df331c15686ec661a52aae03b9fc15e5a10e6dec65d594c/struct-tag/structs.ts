import { bcsSource as bcs } from "../../../../_framework/bcs"
import { FieldsWithTypes, Type } from "../../../../_framework/util"
import { String } from "../../0x1/string/structs"
import { ID } from "../../0x2/object/structs"
import { Encoding } from "@mysten/bcs"
import { ObjectId } from "@mysten/sui.js"

/* ============================== StructTag =============================== */

bcs.registerStructType(
    "0x390d9fbd00f96974df331c15686ec661a52aae03b9fc15e5a10e6dec65d594c::struct_tag::StructTag",
    {
        package_id: `0x2::object::ID`,
        module_name: `0x1::string::String`,
        struct_name: `0x1::string::String`,
        generics: `vector<0x1::string::String>`,
    }
)

export function isStructTag(type: Type): boolean {
    return (
        type ===
        "0x390d9fbd00f96974df331c15686ec661a52aae03b9fc15e5a10e6dec65d594c::struct_tag::StructTag"
    )
}

export interface StructTagFields {
    packageId: ObjectId
    moduleName: string
    structName: string
    generics: Array<string>
}

export class StructTag {
    static readonly $typeName =
        "0x390d9fbd00f96974df331c15686ec661a52aae03b9fc15e5a10e6dec65d594c::struct_tag::StructTag"
    static readonly $numTypeParams = 0

    readonly packageId: ObjectId
    readonly moduleName: string
    readonly structName: string
    readonly generics: Array<string>

    constructor(fields: StructTagFields) {
        this.packageId = fields.packageId
        this.moduleName = fields.moduleName
        this.structName = fields.structName
        this.generics = fields.generics
    }

    static fromFields(fields: Record<string, any>): StructTag {
        return new StructTag({
            packageId: ID.fromFields(fields.package_id).bytes,
            moduleName: new TextDecoder()
                .decode(Uint8Array.from(String.fromFields(fields.module_name).bytes))
                .toString(),
            structName: new TextDecoder()
                .decode(Uint8Array.from(String.fromFields(fields.struct_name).bytes))
                .toString(),
            generics: fields.generics.map((item: any) =>
                new TextDecoder().decode(Uint8Array.from(String.fromFields(item).bytes)).toString()
            ),
        })
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): StructTag {
        if (!isStructTag(item.type)) {
            throw new Error("not a StructTag type")
        }
        return new StructTag({
            packageId: item.fields.package_id,
            moduleName: item.fields.module_name,
            structName: item.fields.struct_name,
            generics: item.fields.generics.map((item: any) => item),
        })
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): StructTag {
        return StructTag.fromFields(bcs.de([StructTag.$typeName], data, encoding))
    }
}
