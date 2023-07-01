import { UID } from "../../_dependencies/source/0x2/object/structs"
import { bcsSource as bcs } from "../../_framework/bcs"
import { FieldsWithTypes, Type } from "../../_framework/util"
import { Encoding } from "@mysten/bcs"
import { JsonRpcProvider, ObjectId, SuiParsedData } from "@mysten/sui.js"

/* ============================== Outlaw =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::outlaw_sky::Outlaw",
    {
        id: `0x2::object::UID`,
    }
)

export function isOutlaw(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::outlaw_sky::Outlaw"
    )
}

export interface OutlawFields {
    id: ObjectId
}

export class Outlaw {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::outlaw_sky::Outlaw"
    static readonly $numTypeParams = 0

    readonly id: ObjectId

    constructor(id: ObjectId) {
        this.id = id
    }

    static fromFields(fields: Record<string, any>): Outlaw {
        return new Outlaw(UID.fromFields(fields.id).id)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): Outlaw {
        if (!isOutlaw(item.type)) {
            throw new Error("not a Outlaw type")
        }
        return new Outlaw(item.fields.id.id)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): Outlaw {
        return Outlaw.fromFields(bcs.de([Outlaw.$typeName], data, encoding))
    }

    static fromSuiParsedData(content: SuiParsedData) {
        if (content.dataType !== "moveObject") {
            throw new Error("not an object")
        }
        if (!isOutlaw(content.type)) {
            throw new Error(`object at ${content.fields.id} is not a Outlaw object`)
        }
        return Outlaw.fromFieldsWithTypes(content)
    }

    static async fetch(provider: JsonRpcProvider, id: ObjectId): Promise<Outlaw> {
        const res = await provider.getObject({ id, options: { showContent: true } })
        if (res.error) {
            throw new Error(`error fetching Outlaw object at id ${id}: ${res.error.code}`)
        }
        if (res.data?.content?.dataType !== "moveObject" || !isOutlaw(res.data.content.type)) {
            throw new Error(`object at id ${id} is not a Outlaw object`)
        }
        return Outlaw.fromFieldsWithTypes(res.data.content)
    }
}

/* ============================== Witness =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::outlaw_sky::Witness",
    {
        dummy_field: `bool`,
    }
)

export function isWitness(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::outlaw_sky::Witness"
    )
}

export interface WitnessFields {
    dummyField: boolean
}

export class Witness {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::outlaw_sky::Witness"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): Witness {
        return new Witness(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): Witness {
        if (!isWitness(item.type)) {
            throw new Error("not a Witness type")
        }
        return new Witness(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): Witness {
        return Witness.fromFields(bcs.de([Witness.$typeName], data, encoding))
    }
}

/* ============================== CREATOR =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::outlaw_sky::CREATOR",
    {
        dummy_field: `bool`,
    }
)

export function isCREATOR(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::outlaw_sky::CREATOR"
    )
}

export interface CREATORFields {
    dummyField: boolean
}

export class CREATOR {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::outlaw_sky::CREATOR"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): CREATOR {
        return new CREATOR(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): CREATOR {
        if (!isCREATOR(item.type)) {
            throw new Error("not a CREATOR type")
        }
        return new CREATOR(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): CREATOR {
        return CREATOR.fromFields(bcs.de([CREATOR.$typeName], data, encoding))
    }
}

/* ============================== OUTLAW_SKY =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::outlaw_sky::OUTLAW_SKY",
    {
        dummy_field: `bool`,
    }
)

export function isOUTLAW_SKY(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::outlaw_sky::OUTLAW_SKY"
    )
}

export interface OUTLAW_SKYFields {
    dummyField: boolean
}

export class OUTLAW_SKY {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::outlaw_sky::OUTLAW_SKY"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): OUTLAW_SKY {
        return new OUTLAW_SKY(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): OUTLAW_SKY {
        if (!isOUTLAW_SKY(item.type)) {
            throw new Error("not a OUTLAW_SKY type")
        }
        return new OUTLAW_SKY(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): OUTLAW_SKY {
        return OUTLAW_SKY.fromFields(bcs.de([OUTLAW_SKY.$typeName], data, encoding))
    }
}

/* ============================== USER =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::outlaw_sky::USER",
    {
        dummy_field: `bool`,
    }
)

export function isUSER(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::outlaw_sky::USER"
    )
}

export interface USERFields {
    dummyField: boolean
}

export class USER {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::outlaw_sky::USER"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): USER {
        return new USER(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): USER {
        if (!isUSER(item.type)) {
            throw new Error("not a USER type")
        }
        return new USER(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): USER {
        return USER.fromFields(bcs.de([USER.$typeName], data, encoding))
    }
}
