import { bcsSource as bcs } from "../../_framework/bcs"
import { FieldsWithTypes, Type } from "../../_framework/util"
import { Encoding } from "@mysten/bcs"

/* ============================== ACTION_1 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_1",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_1(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_1"
    )
}

export interface ACTION_1Fields {
    dummyField: boolean
}

export class ACTION_1 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_1"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_1 {
        return new ACTION_1(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_1 {
        if (!isACTION_1(item.type)) {
            throw new Error("not a ACTION_1 type")
        }
        return new ACTION_1(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_1 {
        return ACTION_1.fromFields(bcs.de([ACTION_1.$typeName], data, encoding))
    }
}

/* ============================== ACTION_10 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_10",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_10(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_10"
    )
}

export interface ACTION_10Fields {
    dummyField: boolean
}

export class ACTION_10 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_10"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_10 {
        return new ACTION_10(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_10 {
        if (!isACTION_10(item.type)) {
            throw new Error("not a ACTION_10 type")
        }
        return new ACTION_10(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_10 {
        return ACTION_10.fromFields(bcs.de([ACTION_10.$typeName], data, encoding))
    }
}

/* ============================== ACTION_100 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_100",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_100(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_100"
    )
}

export interface ACTION_100Fields {
    dummyField: boolean
}

export class ACTION_100 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_100"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_100 {
        return new ACTION_100(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_100 {
        if (!isACTION_100(item.type)) {
            throw new Error("not a ACTION_100 type")
        }
        return new ACTION_100(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_100 {
        return ACTION_100.fromFields(bcs.de([ACTION_100.$typeName], data, encoding))
    }
}

/* ============================== ACTION_11 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_11",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_11(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_11"
    )
}

export interface ACTION_11Fields {
    dummyField: boolean
}

export class ACTION_11 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_11"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_11 {
        return new ACTION_11(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_11 {
        if (!isACTION_11(item.type)) {
            throw new Error("not a ACTION_11 type")
        }
        return new ACTION_11(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_11 {
        return ACTION_11.fromFields(bcs.de([ACTION_11.$typeName], data, encoding))
    }
}

/* ============================== ACTION_12 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_12",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_12(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_12"
    )
}

export interface ACTION_12Fields {
    dummyField: boolean
}

export class ACTION_12 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_12"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_12 {
        return new ACTION_12(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_12 {
        if (!isACTION_12(item.type)) {
            throw new Error("not a ACTION_12 type")
        }
        return new ACTION_12(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_12 {
        return ACTION_12.fromFields(bcs.de([ACTION_12.$typeName], data, encoding))
    }
}

/* ============================== ACTION_13 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_13",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_13(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_13"
    )
}

export interface ACTION_13Fields {
    dummyField: boolean
}

export class ACTION_13 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_13"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_13 {
        return new ACTION_13(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_13 {
        if (!isACTION_13(item.type)) {
            throw new Error("not a ACTION_13 type")
        }
        return new ACTION_13(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_13 {
        return ACTION_13.fromFields(bcs.de([ACTION_13.$typeName], data, encoding))
    }
}

/* ============================== ACTION_14 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_14",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_14(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_14"
    )
}

export interface ACTION_14Fields {
    dummyField: boolean
}

export class ACTION_14 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_14"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_14 {
        return new ACTION_14(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_14 {
        if (!isACTION_14(item.type)) {
            throw new Error("not a ACTION_14 type")
        }
        return new ACTION_14(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_14 {
        return ACTION_14.fromFields(bcs.de([ACTION_14.$typeName], data, encoding))
    }
}

/* ============================== ACTION_15 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_15",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_15(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_15"
    )
}

export interface ACTION_15Fields {
    dummyField: boolean
}

export class ACTION_15 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_15"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_15 {
        return new ACTION_15(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_15 {
        if (!isACTION_15(item.type)) {
            throw new Error("not a ACTION_15 type")
        }
        return new ACTION_15(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_15 {
        return ACTION_15.fromFields(bcs.de([ACTION_15.$typeName], data, encoding))
    }
}

/* ============================== ACTION_16 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_16",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_16(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_16"
    )
}

export interface ACTION_16Fields {
    dummyField: boolean
}

export class ACTION_16 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_16"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_16 {
        return new ACTION_16(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_16 {
        if (!isACTION_16(item.type)) {
            throw new Error("not a ACTION_16 type")
        }
        return new ACTION_16(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_16 {
        return ACTION_16.fromFields(bcs.de([ACTION_16.$typeName], data, encoding))
    }
}

/* ============================== ACTION_17 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_17",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_17(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_17"
    )
}

export interface ACTION_17Fields {
    dummyField: boolean
}

export class ACTION_17 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_17"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_17 {
        return new ACTION_17(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_17 {
        if (!isACTION_17(item.type)) {
            throw new Error("not a ACTION_17 type")
        }
        return new ACTION_17(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_17 {
        return ACTION_17.fromFields(bcs.de([ACTION_17.$typeName], data, encoding))
    }
}

/* ============================== ACTION_18 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_18",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_18(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_18"
    )
}

export interface ACTION_18Fields {
    dummyField: boolean
}

export class ACTION_18 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_18"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_18 {
        return new ACTION_18(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_18 {
        if (!isACTION_18(item.type)) {
            throw new Error("not a ACTION_18 type")
        }
        return new ACTION_18(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_18 {
        return ACTION_18.fromFields(bcs.de([ACTION_18.$typeName], data, encoding))
    }
}

/* ============================== ACTION_19 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_19",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_19(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_19"
    )
}

export interface ACTION_19Fields {
    dummyField: boolean
}

export class ACTION_19 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_19"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_19 {
        return new ACTION_19(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_19 {
        if (!isACTION_19(item.type)) {
            throw new Error("not a ACTION_19 type")
        }
        return new ACTION_19(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_19 {
        return ACTION_19.fromFields(bcs.de([ACTION_19.$typeName], data, encoding))
    }
}

/* ============================== ACTION_2 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_2",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_2(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_2"
    )
}

export interface ACTION_2Fields {
    dummyField: boolean
}

export class ACTION_2 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_2"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_2 {
        return new ACTION_2(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_2 {
        if (!isACTION_2(item.type)) {
            throw new Error("not a ACTION_2 type")
        }
        return new ACTION_2(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_2 {
        return ACTION_2.fromFields(bcs.de([ACTION_2.$typeName], data, encoding))
    }
}

/* ============================== ACTION_20 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_20",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_20(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_20"
    )
}

export interface ACTION_20Fields {
    dummyField: boolean
}

export class ACTION_20 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_20"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_20 {
        return new ACTION_20(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_20 {
        if (!isACTION_20(item.type)) {
            throw new Error("not a ACTION_20 type")
        }
        return new ACTION_20(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_20 {
        return ACTION_20.fromFields(bcs.de([ACTION_20.$typeName], data, encoding))
    }
}

/* ============================== ACTION_21 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_21",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_21(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_21"
    )
}

export interface ACTION_21Fields {
    dummyField: boolean
}

export class ACTION_21 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_21"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_21 {
        return new ACTION_21(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_21 {
        if (!isACTION_21(item.type)) {
            throw new Error("not a ACTION_21 type")
        }
        return new ACTION_21(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_21 {
        return ACTION_21.fromFields(bcs.de([ACTION_21.$typeName], data, encoding))
    }
}

/* ============================== ACTION_22 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_22",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_22(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_22"
    )
}

export interface ACTION_22Fields {
    dummyField: boolean
}

export class ACTION_22 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_22"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_22 {
        return new ACTION_22(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_22 {
        if (!isACTION_22(item.type)) {
            throw new Error("not a ACTION_22 type")
        }
        return new ACTION_22(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_22 {
        return ACTION_22.fromFields(bcs.de([ACTION_22.$typeName], data, encoding))
    }
}

/* ============================== ACTION_23 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_23",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_23(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_23"
    )
}

export interface ACTION_23Fields {
    dummyField: boolean
}

export class ACTION_23 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_23"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_23 {
        return new ACTION_23(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_23 {
        if (!isACTION_23(item.type)) {
            throw new Error("not a ACTION_23 type")
        }
        return new ACTION_23(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_23 {
        return ACTION_23.fromFields(bcs.de([ACTION_23.$typeName], data, encoding))
    }
}

/* ============================== ACTION_24 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_24",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_24(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_24"
    )
}

export interface ACTION_24Fields {
    dummyField: boolean
}

export class ACTION_24 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_24"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_24 {
        return new ACTION_24(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_24 {
        if (!isACTION_24(item.type)) {
            throw new Error("not a ACTION_24 type")
        }
        return new ACTION_24(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_24 {
        return ACTION_24.fromFields(bcs.de([ACTION_24.$typeName], data, encoding))
    }
}

/* ============================== ACTION_25 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_25",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_25(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_25"
    )
}

export interface ACTION_25Fields {
    dummyField: boolean
}

export class ACTION_25 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_25"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_25 {
        return new ACTION_25(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_25 {
        if (!isACTION_25(item.type)) {
            throw new Error("not a ACTION_25 type")
        }
        return new ACTION_25(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_25 {
        return ACTION_25.fromFields(bcs.de([ACTION_25.$typeName], data, encoding))
    }
}

/* ============================== ACTION_26 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_26",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_26(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_26"
    )
}

export interface ACTION_26Fields {
    dummyField: boolean
}

export class ACTION_26 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_26"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_26 {
        return new ACTION_26(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_26 {
        if (!isACTION_26(item.type)) {
            throw new Error("not a ACTION_26 type")
        }
        return new ACTION_26(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_26 {
        return ACTION_26.fromFields(bcs.de([ACTION_26.$typeName], data, encoding))
    }
}

/* ============================== ACTION_27 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_27",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_27(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_27"
    )
}

export interface ACTION_27Fields {
    dummyField: boolean
}

export class ACTION_27 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_27"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_27 {
        return new ACTION_27(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_27 {
        if (!isACTION_27(item.type)) {
            throw new Error("not a ACTION_27 type")
        }
        return new ACTION_27(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_27 {
        return ACTION_27.fromFields(bcs.de([ACTION_27.$typeName], data, encoding))
    }
}

/* ============================== ACTION_28 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_28",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_28(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_28"
    )
}

export interface ACTION_28Fields {
    dummyField: boolean
}

export class ACTION_28 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_28"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_28 {
        return new ACTION_28(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_28 {
        if (!isACTION_28(item.type)) {
            throw new Error("not a ACTION_28 type")
        }
        return new ACTION_28(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_28 {
        return ACTION_28.fromFields(bcs.de([ACTION_28.$typeName], data, encoding))
    }
}

/* ============================== ACTION_29 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_29",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_29(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_29"
    )
}

export interface ACTION_29Fields {
    dummyField: boolean
}

export class ACTION_29 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_29"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_29 {
        return new ACTION_29(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_29 {
        if (!isACTION_29(item.type)) {
            throw new Error("not a ACTION_29 type")
        }
        return new ACTION_29(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_29 {
        return ACTION_29.fromFields(bcs.de([ACTION_29.$typeName], data, encoding))
    }
}

/* ============================== ACTION_3 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_3",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_3(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_3"
    )
}

export interface ACTION_3Fields {
    dummyField: boolean
}

export class ACTION_3 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_3"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_3 {
        return new ACTION_3(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_3 {
        if (!isACTION_3(item.type)) {
            throw new Error("not a ACTION_3 type")
        }
        return new ACTION_3(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_3 {
        return ACTION_3.fromFields(bcs.de([ACTION_3.$typeName], data, encoding))
    }
}

/* ============================== ACTION_30 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_30",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_30(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_30"
    )
}

export interface ACTION_30Fields {
    dummyField: boolean
}

export class ACTION_30 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_30"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_30 {
        return new ACTION_30(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_30 {
        if (!isACTION_30(item.type)) {
            throw new Error("not a ACTION_30 type")
        }
        return new ACTION_30(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_30 {
        return ACTION_30.fromFields(bcs.de([ACTION_30.$typeName], data, encoding))
    }
}

/* ============================== ACTION_31 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_31",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_31(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_31"
    )
}

export interface ACTION_31Fields {
    dummyField: boolean
}

export class ACTION_31 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_31"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_31 {
        return new ACTION_31(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_31 {
        if (!isACTION_31(item.type)) {
            throw new Error("not a ACTION_31 type")
        }
        return new ACTION_31(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_31 {
        return ACTION_31.fromFields(bcs.de([ACTION_31.$typeName], data, encoding))
    }
}

/* ============================== ACTION_32 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_32",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_32(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_32"
    )
}

export interface ACTION_32Fields {
    dummyField: boolean
}

export class ACTION_32 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_32"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_32 {
        return new ACTION_32(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_32 {
        if (!isACTION_32(item.type)) {
            throw new Error("not a ACTION_32 type")
        }
        return new ACTION_32(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_32 {
        return ACTION_32.fromFields(bcs.de([ACTION_32.$typeName], data, encoding))
    }
}

/* ============================== ACTION_33 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_33",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_33(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_33"
    )
}

export interface ACTION_33Fields {
    dummyField: boolean
}

export class ACTION_33 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_33"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_33 {
        return new ACTION_33(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_33 {
        if (!isACTION_33(item.type)) {
            throw new Error("not a ACTION_33 type")
        }
        return new ACTION_33(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_33 {
        return ACTION_33.fromFields(bcs.de([ACTION_33.$typeName], data, encoding))
    }
}

/* ============================== ACTION_34 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_34",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_34(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_34"
    )
}

export interface ACTION_34Fields {
    dummyField: boolean
}

export class ACTION_34 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_34"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_34 {
        return new ACTION_34(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_34 {
        if (!isACTION_34(item.type)) {
            throw new Error("not a ACTION_34 type")
        }
        return new ACTION_34(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_34 {
        return ACTION_34.fromFields(bcs.de([ACTION_34.$typeName], data, encoding))
    }
}

/* ============================== ACTION_35 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_35",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_35(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_35"
    )
}

export interface ACTION_35Fields {
    dummyField: boolean
}

export class ACTION_35 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_35"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_35 {
        return new ACTION_35(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_35 {
        if (!isACTION_35(item.type)) {
            throw new Error("not a ACTION_35 type")
        }
        return new ACTION_35(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_35 {
        return ACTION_35.fromFields(bcs.de([ACTION_35.$typeName], data, encoding))
    }
}

/* ============================== ACTION_36 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_36",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_36(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_36"
    )
}

export interface ACTION_36Fields {
    dummyField: boolean
}

export class ACTION_36 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_36"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_36 {
        return new ACTION_36(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_36 {
        if (!isACTION_36(item.type)) {
            throw new Error("not a ACTION_36 type")
        }
        return new ACTION_36(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_36 {
        return ACTION_36.fromFields(bcs.de([ACTION_36.$typeName], data, encoding))
    }
}

/* ============================== ACTION_37 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_37",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_37(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_37"
    )
}

export interface ACTION_37Fields {
    dummyField: boolean
}

export class ACTION_37 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_37"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_37 {
        return new ACTION_37(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_37 {
        if (!isACTION_37(item.type)) {
            throw new Error("not a ACTION_37 type")
        }
        return new ACTION_37(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_37 {
        return ACTION_37.fromFields(bcs.de([ACTION_37.$typeName], data, encoding))
    }
}

/* ============================== ACTION_38 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_38",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_38(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_38"
    )
}

export interface ACTION_38Fields {
    dummyField: boolean
}

export class ACTION_38 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_38"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_38 {
        return new ACTION_38(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_38 {
        if (!isACTION_38(item.type)) {
            throw new Error("not a ACTION_38 type")
        }
        return new ACTION_38(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_38 {
        return ACTION_38.fromFields(bcs.de([ACTION_38.$typeName], data, encoding))
    }
}

/* ============================== ACTION_39 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_39",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_39(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_39"
    )
}

export interface ACTION_39Fields {
    dummyField: boolean
}

export class ACTION_39 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_39"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_39 {
        return new ACTION_39(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_39 {
        if (!isACTION_39(item.type)) {
            throw new Error("not a ACTION_39 type")
        }
        return new ACTION_39(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_39 {
        return ACTION_39.fromFields(bcs.de([ACTION_39.$typeName], data, encoding))
    }
}

/* ============================== ACTION_4 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_4",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_4(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_4"
    )
}

export interface ACTION_4Fields {
    dummyField: boolean
}

export class ACTION_4 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_4"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_4 {
        return new ACTION_4(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_4 {
        if (!isACTION_4(item.type)) {
            throw new Error("not a ACTION_4 type")
        }
        return new ACTION_4(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_4 {
        return ACTION_4.fromFields(bcs.de([ACTION_4.$typeName], data, encoding))
    }
}

/* ============================== ACTION_40 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_40",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_40(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_40"
    )
}

export interface ACTION_40Fields {
    dummyField: boolean
}

export class ACTION_40 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_40"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_40 {
        return new ACTION_40(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_40 {
        if (!isACTION_40(item.type)) {
            throw new Error("not a ACTION_40 type")
        }
        return new ACTION_40(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_40 {
        return ACTION_40.fromFields(bcs.de([ACTION_40.$typeName], data, encoding))
    }
}

/* ============================== ACTION_41 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_41",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_41(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_41"
    )
}

export interface ACTION_41Fields {
    dummyField: boolean
}

export class ACTION_41 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_41"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_41 {
        return new ACTION_41(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_41 {
        if (!isACTION_41(item.type)) {
            throw new Error("not a ACTION_41 type")
        }
        return new ACTION_41(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_41 {
        return ACTION_41.fromFields(bcs.de([ACTION_41.$typeName], data, encoding))
    }
}

/* ============================== ACTION_42 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_42",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_42(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_42"
    )
}

export interface ACTION_42Fields {
    dummyField: boolean
}

export class ACTION_42 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_42"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_42 {
        return new ACTION_42(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_42 {
        if (!isACTION_42(item.type)) {
            throw new Error("not a ACTION_42 type")
        }
        return new ACTION_42(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_42 {
        return ACTION_42.fromFields(bcs.de([ACTION_42.$typeName], data, encoding))
    }
}

/* ============================== ACTION_43 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_43",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_43(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_43"
    )
}

export interface ACTION_43Fields {
    dummyField: boolean
}

export class ACTION_43 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_43"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_43 {
        return new ACTION_43(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_43 {
        if (!isACTION_43(item.type)) {
            throw new Error("not a ACTION_43 type")
        }
        return new ACTION_43(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_43 {
        return ACTION_43.fromFields(bcs.de([ACTION_43.$typeName], data, encoding))
    }
}

/* ============================== ACTION_44 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_44",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_44(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_44"
    )
}

export interface ACTION_44Fields {
    dummyField: boolean
}

export class ACTION_44 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_44"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_44 {
        return new ACTION_44(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_44 {
        if (!isACTION_44(item.type)) {
            throw new Error("not a ACTION_44 type")
        }
        return new ACTION_44(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_44 {
        return ACTION_44.fromFields(bcs.de([ACTION_44.$typeName], data, encoding))
    }
}

/* ============================== ACTION_45 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_45",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_45(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_45"
    )
}

export interface ACTION_45Fields {
    dummyField: boolean
}

export class ACTION_45 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_45"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_45 {
        return new ACTION_45(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_45 {
        if (!isACTION_45(item.type)) {
            throw new Error("not a ACTION_45 type")
        }
        return new ACTION_45(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_45 {
        return ACTION_45.fromFields(bcs.de([ACTION_45.$typeName], data, encoding))
    }
}

/* ============================== ACTION_46 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_46",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_46(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_46"
    )
}

export interface ACTION_46Fields {
    dummyField: boolean
}

export class ACTION_46 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_46"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_46 {
        return new ACTION_46(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_46 {
        if (!isACTION_46(item.type)) {
            throw new Error("not a ACTION_46 type")
        }
        return new ACTION_46(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_46 {
        return ACTION_46.fromFields(bcs.de([ACTION_46.$typeName], data, encoding))
    }
}

/* ============================== ACTION_47 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_47",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_47(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_47"
    )
}

export interface ACTION_47Fields {
    dummyField: boolean
}

export class ACTION_47 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_47"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_47 {
        return new ACTION_47(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_47 {
        if (!isACTION_47(item.type)) {
            throw new Error("not a ACTION_47 type")
        }
        return new ACTION_47(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_47 {
        return ACTION_47.fromFields(bcs.de([ACTION_47.$typeName], data, encoding))
    }
}

/* ============================== ACTION_48 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_48",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_48(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_48"
    )
}

export interface ACTION_48Fields {
    dummyField: boolean
}

export class ACTION_48 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_48"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_48 {
        return new ACTION_48(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_48 {
        if (!isACTION_48(item.type)) {
            throw new Error("not a ACTION_48 type")
        }
        return new ACTION_48(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_48 {
        return ACTION_48.fromFields(bcs.de([ACTION_48.$typeName], data, encoding))
    }
}

/* ============================== ACTION_49 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_49",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_49(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_49"
    )
}

export interface ACTION_49Fields {
    dummyField: boolean
}

export class ACTION_49 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_49"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_49 {
        return new ACTION_49(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_49 {
        if (!isACTION_49(item.type)) {
            throw new Error("not a ACTION_49 type")
        }
        return new ACTION_49(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_49 {
        return ACTION_49.fromFields(bcs.de([ACTION_49.$typeName], data, encoding))
    }
}

/* ============================== ACTION_5 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_5",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_5(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_5"
    )
}

export interface ACTION_5Fields {
    dummyField: boolean
}

export class ACTION_5 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_5"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_5 {
        return new ACTION_5(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_5 {
        if (!isACTION_5(item.type)) {
            throw new Error("not a ACTION_5 type")
        }
        return new ACTION_5(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_5 {
        return ACTION_5.fromFields(bcs.de([ACTION_5.$typeName], data, encoding))
    }
}

/* ============================== ACTION_50 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_50",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_50(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_50"
    )
}

export interface ACTION_50Fields {
    dummyField: boolean
}

export class ACTION_50 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_50"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_50 {
        return new ACTION_50(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_50 {
        if (!isACTION_50(item.type)) {
            throw new Error("not a ACTION_50 type")
        }
        return new ACTION_50(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_50 {
        return ACTION_50.fromFields(bcs.de([ACTION_50.$typeName], data, encoding))
    }
}

/* ============================== ACTION_51 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_51",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_51(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_51"
    )
}

export interface ACTION_51Fields {
    dummyField: boolean
}

export class ACTION_51 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_51"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_51 {
        return new ACTION_51(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_51 {
        if (!isACTION_51(item.type)) {
            throw new Error("not a ACTION_51 type")
        }
        return new ACTION_51(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_51 {
        return ACTION_51.fromFields(bcs.de([ACTION_51.$typeName], data, encoding))
    }
}

/* ============================== ACTION_52 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_52",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_52(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_52"
    )
}

export interface ACTION_52Fields {
    dummyField: boolean
}

export class ACTION_52 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_52"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_52 {
        return new ACTION_52(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_52 {
        if (!isACTION_52(item.type)) {
            throw new Error("not a ACTION_52 type")
        }
        return new ACTION_52(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_52 {
        return ACTION_52.fromFields(bcs.de([ACTION_52.$typeName], data, encoding))
    }
}

/* ============================== ACTION_53 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_53",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_53(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_53"
    )
}

export interface ACTION_53Fields {
    dummyField: boolean
}

export class ACTION_53 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_53"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_53 {
        return new ACTION_53(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_53 {
        if (!isACTION_53(item.type)) {
            throw new Error("not a ACTION_53 type")
        }
        return new ACTION_53(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_53 {
        return ACTION_53.fromFields(bcs.de([ACTION_53.$typeName], data, encoding))
    }
}

/* ============================== ACTION_54 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_54",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_54(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_54"
    )
}

export interface ACTION_54Fields {
    dummyField: boolean
}

export class ACTION_54 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_54"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_54 {
        return new ACTION_54(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_54 {
        if (!isACTION_54(item.type)) {
            throw new Error("not a ACTION_54 type")
        }
        return new ACTION_54(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_54 {
        return ACTION_54.fromFields(bcs.de([ACTION_54.$typeName], data, encoding))
    }
}

/* ============================== ACTION_55 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_55",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_55(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_55"
    )
}

export interface ACTION_55Fields {
    dummyField: boolean
}

export class ACTION_55 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_55"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_55 {
        return new ACTION_55(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_55 {
        if (!isACTION_55(item.type)) {
            throw new Error("not a ACTION_55 type")
        }
        return new ACTION_55(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_55 {
        return ACTION_55.fromFields(bcs.de([ACTION_55.$typeName], data, encoding))
    }
}

/* ============================== ACTION_56 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_56",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_56(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_56"
    )
}

export interface ACTION_56Fields {
    dummyField: boolean
}

export class ACTION_56 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_56"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_56 {
        return new ACTION_56(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_56 {
        if (!isACTION_56(item.type)) {
            throw new Error("not a ACTION_56 type")
        }
        return new ACTION_56(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_56 {
        return ACTION_56.fromFields(bcs.de([ACTION_56.$typeName], data, encoding))
    }
}

/* ============================== ACTION_57 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_57",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_57(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_57"
    )
}

export interface ACTION_57Fields {
    dummyField: boolean
}

export class ACTION_57 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_57"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_57 {
        return new ACTION_57(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_57 {
        if (!isACTION_57(item.type)) {
            throw new Error("not a ACTION_57 type")
        }
        return new ACTION_57(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_57 {
        return ACTION_57.fromFields(bcs.de([ACTION_57.$typeName], data, encoding))
    }
}

/* ============================== ACTION_58 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_58",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_58(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_58"
    )
}

export interface ACTION_58Fields {
    dummyField: boolean
}

export class ACTION_58 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_58"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_58 {
        return new ACTION_58(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_58 {
        if (!isACTION_58(item.type)) {
            throw new Error("not a ACTION_58 type")
        }
        return new ACTION_58(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_58 {
        return ACTION_58.fromFields(bcs.de([ACTION_58.$typeName], data, encoding))
    }
}

/* ============================== ACTION_59 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_59",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_59(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_59"
    )
}

export interface ACTION_59Fields {
    dummyField: boolean
}

export class ACTION_59 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_59"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_59 {
        return new ACTION_59(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_59 {
        if (!isACTION_59(item.type)) {
            throw new Error("not a ACTION_59 type")
        }
        return new ACTION_59(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_59 {
        return ACTION_59.fromFields(bcs.de([ACTION_59.$typeName], data, encoding))
    }
}

/* ============================== ACTION_6 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_6",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_6(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_6"
    )
}

export interface ACTION_6Fields {
    dummyField: boolean
}

export class ACTION_6 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_6"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_6 {
        return new ACTION_6(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_6 {
        if (!isACTION_6(item.type)) {
            throw new Error("not a ACTION_6 type")
        }
        return new ACTION_6(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_6 {
        return ACTION_6.fromFields(bcs.de([ACTION_6.$typeName], data, encoding))
    }
}

/* ============================== ACTION_60 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_60",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_60(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_60"
    )
}

export interface ACTION_60Fields {
    dummyField: boolean
}

export class ACTION_60 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_60"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_60 {
        return new ACTION_60(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_60 {
        if (!isACTION_60(item.type)) {
            throw new Error("not a ACTION_60 type")
        }
        return new ACTION_60(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_60 {
        return ACTION_60.fromFields(bcs.de([ACTION_60.$typeName], data, encoding))
    }
}

/* ============================== ACTION_61 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_61",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_61(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_61"
    )
}

export interface ACTION_61Fields {
    dummyField: boolean
}

export class ACTION_61 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_61"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_61 {
        return new ACTION_61(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_61 {
        if (!isACTION_61(item.type)) {
            throw new Error("not a ACTION_61 type")
        }
        return new ACTION_61(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_61 {
        return ACTION_61.fromFields(bcs.de([ACTION_61.$typeName], data, encoding))
    }
}

/* ============================== ACTION_62 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_62",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_62(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_62"
    )
}

export interface ACTION_62Fields {
    dummyField: boolean
}

export class ACTION_62 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_62"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_62 {
        return new ACTION_62(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_62 {
        if (!isACTION_62(item.type)) {
            throw new Error("not a ACTION_62 type")
        }
        return new ACTION_62(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_62 {
        return ACTION_62.fromFields(bcs.de([ACTION_62.$typeName], data, encoding))
    }
}

/* ============================== ACTION_63 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_63",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_63(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_63"
    )
}

export interface ACTION_63Fields {
    dummyField: boolean
}

export class ACTION_63 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_63"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_63 {
        return new ACTION_63(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_63 {
        if (!isACTION_63(item.type)) {
            throw new Error("not a ACTION_63 type")
        }
        return new ACTION_63(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_63 {
        return ACTION_63.fromFields(bcs.de([ACTION_63.$typeName], data, encoding))
    }
}

/* ============================== ACTION_64 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_64",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_64(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_64"
    )
}

export interface ACTION_64Fields {
    dummyField: boolean
}

export class ACTION_64 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_64"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_64 {
        return new ACTION_64(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_64 {
        if (!isACTION_64(item.type)) {
            throw new Error("not a ACTION_64 type")
        }
        return new ACTION_64(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_64 {
        return ACTION_64.fromFields(bcs.de([ACTION_64.$typeName], data, encoding))
    }
}

/* ============================== ACTION_65 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_65",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_65(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_65"
    )
}

export interface ACTION_65Fields {
    dummyField: boolean
}

export class ACTION_65 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_65"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_65 {
        return new ACTION_65(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_65 {
        if (!isACTION_65(item.type)) {
            throw new Error("not a ACTION_65 type")
        }
        return new ACTION_65(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_65 {
        return ACTION_65.fromFields(bcs.de([ACTION_65.$typeName], data, encoding))
    }
}

/* ============================== ACTION_66 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_66",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_66(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_66"
    )
}

export interface ACTION_66Fields {
    dummyField: boolean
}

export class ACTION_66 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_66"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_66 {
        return new ACTION_66(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_66 {
        if (!isACTION_66(item.type)) {
            throw new Error("not a ACTION_66 type")
        }
        return new ACTION_66(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_66 {
        return ACTION_66.fromFields(bcs.de([ACTION_66.$typeName], data, encoding))
    }
}

/* ============================== ACTION_67 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_67",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_67(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_67"
    )
}

export interface ACTION_67Fields {
    dummyField: boolean
}

export class ACTION_67 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_67"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_67 {
        return new ACTION_67(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_67 {
        if (!isACTION_67(item.type)) {
            throw new Error("not a ACTION_67 type")
        }
        return new ACTION_67(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_67 {
        return ACTION_67.fromFields(bcs.de([ACTION_67.$typeName], data, encoding))
    }
}

/* ============================== ACTION_68 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_68",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_68(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_68"
    )
}

export interface ACTION_68Fields {
    dummyField: boolean
}

export class ACTION_68 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_68"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_68 {
        return new ACTION_68(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_68 {
        if (!isACTION_68(item.type)) {
            throw new Error("not a ACTION_68 type")
        }
        return new ACTION_68(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_68 {
        return ACTION_68.fromFields(bcs.de([ACTION_68.$typeName], data, encoding))
    }
}

/* ============================== ACTION_69 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_69",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_69(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_69"
    )
}

export interface ACTION_69Fields {
    dummyField: boolean
}

export class ACTION_69 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_69"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_69 {
        return new ACTION_69(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_69 {
        if (!isACTION_69(item.type)) {
            throw new Error("not a ACTION_69 type")
        }
        return new ACTION_69(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_69 {
        return ACTION_69.fromFields(bcs.de([ACTION_69.$typeName], data, encoding))
    }
}

/* ============================== ACTION_7 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_7",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_7(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_7"
    )
}

export interface ACTION_7Fields {
    dummyField: boolean
}

export class ACTION_7 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_7"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_7 {
        return new ACTION_7(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_7 {
        if (!isACTION_7(item.type)) {
            throw new Error("not a ACTION_7 type")
        }
        return new ACTION_7(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_7 {
        return ACTION_7.fromFields(bcs.de([ACTION_7.$typeName], data, encoding))
    }
}

/* ============================== ACTION_70 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_70",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_70(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_70"
    )
}

export interface ACTION_70Fields {
    dummyField: boolean
}

export class ACTION_70 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_70"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_70 {
        return new ACTION_70(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_70 {
        if (!isACTION_70(item.type)) {
            throw new Error("not a ACTION_70 type")
        }
        return new ACTION_70(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_70 {
        return ACTION_70.fromFields(bcs.de([ACTION_70.$typeName], data, encoding))
    }
}

/* ============================== ACTION_71 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_71",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_71(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_71"
    )
}

export interface ACTION_71Fields {
    dummyField: boolean
}

export class ACTION_71 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_71"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_71 {
        return new ACTION_71(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_71 {
        if (!isACTION_71(item.type)) {
            throw new Error("not a ACTION_71 type")
        }
        return new ACTION_71(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_71 {
        return ACTION_71.fromFields(bcs.de([ACTION_71.$typeName], data, encoding))
    }
}

/* ============================== ACTION_72 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_72",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_72(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_72"
    )
}

export interface ACTION_72Fields {
    dummyField: boolean
}

export class ACTION_72 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_72"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_72 {
        return new ACTION_72(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_72 {
        if (!isACTION_72(item.type)) {
            throw new Error("not a ACTION_72 type")
        }
        return new ACTION_72(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_72 {
        return ACTION_72.fromFields(bcs.de([ACTION_72.$typeName], data, encoding))
    }
}

/* ============================== ACTION_73 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_73",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_73(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_73"
    )
}

export interface ACTION_73Fields {
    dummyField: boolean
}

export class ACTION_73 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_73"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_73 {
        return new ACTION_73(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_73 {
        if (!isACTION_73(item.type)) {
            throw new Error("not a ACTION_73 type")
        }
        return new ACTION_73(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_73 {
        return ACTION_73.fromFields(bcs.de([ACTION_73.$typeName], data, encoding))
    }
}

/* ============================== ACTION_74 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_74",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_74(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_74"
    )
}

export interface ACTION_74Fields {
    dummyField: boolean
}

export class ACTION_74 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_74"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_74 {
        return new ACTION_74(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_74 {
        if (!isACTION_74(item.type)) {
            throw new Error("not a ACTION_74 type")
        }
        return new ACTION_74(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_74 {
        return ACTION_74.fromFields(bcs.de([ACTION_74.$typeName], data, encoding))
    }
}

/* ============================== ACTION_75 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_75",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_75(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_75"
    )
}

export interface ACTION_75Fields {
    dummyField: boolean
}

export class ACTION_75 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_75"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_75 {
        return new ACTION_75(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_75 {
        if (!isACTION_75(item.type)) {
            throw new Error("not a ACTION_75 type")
        }
        return new ACTION_75(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_75 {
        return ACTION_75.fromFields(bcs.de([ACTION_75.$typeName], data, encoding))
    }
}

/* ============================== ACTION_76 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_76",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_76(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_76"
    )
}

export interface ACTION_76Fields {
    dummyField: boolean
}

export class ACTION_76 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_76"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_76 {
        return new ACTION_76(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_76 {
        if (!isACTION_76(item.type)) {
            throw new Error("not a ACTION_76 type")
        }
        return new ACTION_76(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_76 {
        return ACTION_76.fromFields(bcs.de([ACTION_76.$typeName], data, encoding))
    }
}

/* ============================== ACTION_77 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_77",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_77(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_77"
    )
}

export interface ACTION_77Fields {
    dummyField: boolean
}

export class ACTION_77 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_77"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_77 {
        return new ACTION_77(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_77 {
        if (!isACTION_77(item.type)) {
            throw new Error("not a ACTION_77 type")
        }
        return new ACTION_77(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_77 {
        return ACTION_77.fromFields(bcs.de([ACTION_77.$typeName], data, encoding))
    }
}

/* ============================== ACTION_78 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_78",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_78(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_78"
    )
}

export interface ACTION_78Fields {
    dummyField: boolean
}

export class ACTION_78 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_78"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_78 {
        return new ACTION_78(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_78 {
        if (!isACTION_78(item.type)) {
            throw new Error("not a ACTION_78 type")
        }
        return new ACTION_78(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_78 {
        return ACTION_78.fromFields(bcs.de([ACTION_78.$typeName], data, encoding))
    }
}

/* ============================== ACTION_79 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_79",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_79(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_79"
    )
}

export interface ACTION_79Fields {
    dummyField: boolean
}

export class ACTION_79 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_79"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_79 {
        return new ACTION_79(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_79 {
        if (!isACTION_79(item.type)) {
            throw new Error("not a ACTION_79 type")
        }
        return new ACTION_79(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_79 {
        return ACTION_79.fromFields(bcs.de([ACTION_79.$typeName], data, encoding))
    }
}

/* ============================== ACTION_8 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_8",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_8(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_8"
    )
}

export interface ACTION_8Fields {
    dummyField: boolean
}

export class ACTION_8 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_8"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_8 {
        return new ACTION_8(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_8 {
        if (!isACTION_8(item.type)) {
            throw new Error("not a ACTION_8 type")
        }
        return new ACTION_8(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_8 {
        return ACTION_8.fromFields(bcs.de([ACTION_8.$typeName], data, encoding))
    }
}

/* ============================== ACTION_80 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_80",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_80(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_80"
    )
}

export interface ACTION_80Fields {
    dummyField: boolean
}

export class ACTION_80 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_80"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_80 {
        return new ACTION_80(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_80 {
        if (!isACTION_80(item.type)) {
            throw new Error("not a ACTION_80 type")
        }
        return new ACTION_80(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_80 {
        return ACTION_80.fromFields(bcs.de([ACTION_80.$typeName], data, encoding))
    }
}

/* ============================== ACTION_81 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_81",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_81(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_81"
    )
}

export interface ACTION_81Fields {
    dummyField: boolean
}

export class ACTION_81 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_81"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_81 {
        return new ACTION_81(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_81 {
        if (!isACTION_81(item.type)) {
            throw new Error("not a ACTION_81 type")
        }
        return new ACTION_81(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_81 {
        return ACTION_81.fromFields(bcs.de([ACTION_81.$typeName], data, encoding))
    }
}

/* ============================== ACTION_82 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_82",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_82(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_82"
    )
}

export interface ACTION_82Fields {
    dummyField: boolean
}

export class ACTION_82 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_82"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_82 {
        return new ACTION_82(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_82 {
        if (!isACTION_82(item.type)) {
            throw new Error("not a ACTION_82 type")
        }
        return new ACTION_82(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_82 {
        return ACTION_82.fromFields(bcs.de([ACTION_82.$typeName], data, encoding))
    }
}

/* ============================== ACTION_83 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_83",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_83(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_83"
    )
}

export interface ACTION_83Fields {
    dummyField: boolean
}

export class ACTION_83 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_83"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_83 {
        return new ACTION_83(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_83 {
        if (!isACTION_83(item.type)) {
            throw new Error("not a ACTION_83 type")
        }
        return new ACTION_83(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_83 {
        return ACTION_83.fromFields(bcs.de([ACTION_83.$typeName], data, encoding))
    }
}

/* ============================== ACTION_84 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_84",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_84(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_84"
    )
}

export interface ACTION_84Fields {
    dummyField: boolean
}

export class ACTION_84 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_84"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_84 {
        return new ACTION_84(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_84 {
        if (!isACTION_84(item.type)) {
            throw new Error("not a ACTION_84 type")
        }
        return new ACTION_84(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_84 {
        return ACTION_84.fromFields(bcs.de([ACTION_84.$typeName], data, encoding))
    }
}

/* ============================== ACTION_85 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_85",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_85(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_85"
    )
}

export interface ACTION_85Fields {
    dummyField: boolean
}

export class ACTION_85 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_85"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_85 {
        return new ACTION_85(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_85 {
        if (!isACTION_85(item.type)) {
            throw new Error("not a ACTION_85 type")
        }
        return new ACTION_85(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_85 {
        return ACTION_85.fromFields(bcs.de([ACTION_85.$typeName], data, encoding))
    }
}

/* ============================== ACTION_86 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_86",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_86(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_86"
    )
}

export interface ACTION_86Fields {
    dummyField: boolean
}

export class ACTION_86 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_86"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_86 {
        return new ACTION_86(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_86 {
        if (!isACTION_86(item.type)) {
            throw new Error("not a ACTION_86 type")
        }
        return new ACTION_86(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_86 {
        return ACTION_86.fromFields(bcs.de([ACTION_86.$typeName], data, encoding))
    }
}

/* ============================== ACTION_87 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_87",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_87(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_87"
    )
}

export interface ACTION_87Fields {
    dummyField: boolean
}

export class ACTION_87 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_87"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_87 {
        return new ACTION_87(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_87 {
        if (!isACTION_87(item.type)) {
            throw new Error("not a ACTION_87 type")
        }
        return new ACTION_87(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_87 {
        return ACTION_87.fromFields(bcs.de([ACTION_87.$typeName], data, encoding))
    }
}

/* ============================== ACTION_88 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_88",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_88(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_88"
    )
}

export interface ACTION_88Fields {
    dummyField: boolean
}

export class ACTION_88 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_88"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_88 {
        return new ACTION_88(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_88 {
        if (!isACTION_88(item.type)) {
            throw new Error("not a ACTION_88 type")
        }
        return new ACTION_88(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_88 {
        return ACTION_88.fromFields(bcs.de([ACTION_88.$typeName], data, encoding))
    }
}

/* ============================== ACTION_89 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_89",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_89(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_89"
    )
}

export interface ACTION_89Fields {
    dummyField: boolean
}

export class ACTION_89 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_89"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_89 {
        return new ACTION_89(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_89 {
        if (!isACTION_89(item.type)) {
            throw new Error("not a ACTION_89 type")
        }
        return new ACTION_89(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_89 {
        return ACTION_89.fromFields(bcs.de([ACTION_89.$typeName], data, encoding))
    }
}

/* ============================== ACTION_9 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_9",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_9(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_9"
    )
}

export interface ACTION_9Fields {
    dummyField: boolean
}

export class ACTION_9 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_9"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_9 {
        return new ACTION_9(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_9 {
        if (!isACTION_9(item.type)) {
            throw new Error("not a ACTION_9 type")
        }
        return new ACTION_9(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_9 {
        return ACTION_9.fromFields(bcs.de([ACTION_9.$typeName], data, encoding))
    }
}

/* ============================== ACTION_90 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_90",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_90(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_90"
    )
}

export interface ACTION_90Fields {
    dummyField: boolean
}

export class ACTION_90 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_90"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_90 {
        return new ACTION_90(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_90 {
        if (!isACTION_90(item.type)) {
            throw new Error("not a ACTION_90 type")
        }
        return new ACTION_90(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_90 {
        return ACTION_90.fromFields(bcs.de([ACTION_90.$typeName], data, encoding))
    }
}

/* ============================== ACTION_91 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_91",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_91(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_91"
    )
}

export interface ACTION_91Fields {
    dummyField: boolean
}

export class ACTION_91 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_91"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_91 {
        return new ACTION_91(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_91 {
        if (!isACTION_91(item.type)) {
            throw new Error("not a ACTION_91 type")
        }
        return new ACTION_91(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_91 {
        return ACTION_91.fromFields(bcs.de([ACTION_91.$typeName], data, encoding))
    }
}

/* ============================== ACTION_92 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_92",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_92(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_92"
    )
}

export interface ACTION_92Fields {
    dummyField: boolean
}

export class ACTION_92 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_92"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_92 {
        return new ACTION_92(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_92 {
        if (!isACTION_92(item.type)) {
            throw new Error("not a ACTION_92 type")
        }
        return new ACTION_92(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_92 {
        return ACTION_92.fromFields(bcs.de([ACTION_92.$typeName], data, encoding))
    }
}

/* ============================== ACTION_93 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_93",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_93(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_93"
    )
}

export interface ACTION_93Fields {
    dummyField: boolean
}

export class ACTION_93 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_93"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_93 {
        return new ACTION_93(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_93 {
        if (!isACTION_93(item.type)) {
            throw new Error("not a ACTION_93 type")
        }
        return new ACTION_93(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_93 {
        return ACTION_93.fromFields(bcs.de([ACTION_93.$typeName], data, encoding))
    }
}

/* ============================== ACTION_94 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_94",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_94(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_94"
    )
}

export interface ACTION_94Fields {
    dummyField: boolean
}

export class ACTION_94 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_94"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_94 {
        return new ACTION_94(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_94 {
        if (!isACTION_94(item.type)) {
            throw new Error("not a ACTION_94 type")
        }
        return new ACTION_94(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_94 {
        return ACTION_94.fromFields(bcs.de([ACTION_94.$typeName], data, encoding))
    }
}

/* ============================== ACTION_95 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_95",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_95(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_95"
    )
}

export interface ACTION_95Fields {
    dummyField: boolean
}

export class ACTION_95 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_95"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_95 {
        return new ACTION_95(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_95 {
        if (!isACTION_95(item.type)) {
            throw new Error("not a ACTION_95 type")
        }
        return new ACTION_95(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_95 {
        return ACTION_95.fromFields(bcs.de([ACTION_95.$typeName], data, encoding))
    }
}

/* ============================== ACTION_96 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_96",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_96(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_96"
    )
}

export interface ACTION_96Fields {
    dummyField: boolean
}

export class ACTION_96 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_96"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_96 {
        return new ACTION_96(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_96 {
        if (!isACTION_96(item.type)) {
            throw new Error("not a ACTION_96 type")
        }
        return new ACTION_96(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_96 {
        return ACTION_96.fromFields(bcs.de([ACTION_96.$typeName], data, encoding))
    }
}

/* ============================== ACTION_97 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_97",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_97(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_97"
    )
}

export interface ACTION_97Fields {
    dummyField: boolean
}

export class ACTION_97 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_97"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_97 {
        return new ACTION_97(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_97 {
        if (!isACTION_97(item.type)) {
            throw new Error("not a ACTION_97 type")
        }
        return new ACTION_97(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_97 {
        return ACTION_97.fromFields(bcs.de([ACTION_97.$typeName], data, encoding))
    }
}

/* ============================== ACTION_98 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_98",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_98(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_98"
    )
}

export interface ACTION_98Fields {
    dummyField: boolean
}

export class ACTION_98 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_98"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_98 {
        return new ACTION_98(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_98 {
        if (!isACTION_98(item.type)) {
            throw new Error("not a ACTION_98 type")
        }
        return new ACTION_98(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_98 {
        return ACTION_98.fromFields(bcs.de([ACTION_98.$typeName], data, encoding))
    }
}

/* ============================== ACTION_99 =============================== */

bcs.registerStructType(
    "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_99",
    {
        dummy_field: `bool`,
    }
)

export function isACTION_99(type: Type): boolean {
    return (
        type ===
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_99"
    )
}

export interface ACTION_99Fields {
    dummyField: boolean
}

export class ACTION_99 {
    static readonly $typeName =
        "0x68d0d4a8bd43e4ac81eaa9049ed13fbd4ab8cad89f80e0688ec9316084236b64::actions::ACTION_99"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ACTION_99 {
        return new ACTION_99(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ACTION_99 {
        if (!isACTION_99(item.type)) {
            throw new Error("not a ACTION_99 type")
        }
        return new ACTION_99(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ACTION_99 {
        return ACTION_99.fromFields(bcs.de([ACTION_99.$typeName], data, encoding))
    }
}
