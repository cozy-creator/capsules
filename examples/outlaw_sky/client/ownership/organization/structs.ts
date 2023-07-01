import { ID, UID } from "../../_dependencies/source/0x2/object/structs"
import { bcsSource as bcs } from "../../_framework/bcs"
import { FieldsWithTypes, Type } from "../../_framework/util"
import { RBAC } from "../rbac/structs"
import { Encoding } from "@mysten/bcs"
import { JsonRpcProvider, ObjectId, SuiParsedData } from "@mysten/sui.js"

/* ============================== Witness =============================== */

bcs.registerStructType(
    "0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::organization::Witness",
    {
        dummy_field: `bool`,
    }
)

export function isWitness(type: Type): boolean {
    return (
        type ===
        "0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::organization::Witness"
    )
}

export interface WitnessFields {
    dummyField: boolean
}

export class Witness {
    static readonly $typeName =
        "0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::organization::Witness"
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

/* ============================== Package =============================== */

bcs.registerStructType(
    "0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::organization::Package",
    {
        id: `0x2::object::UID`,
        package_id: `0x2::object::ID`,
    }
)

export function isPackage(type: Type): boolean {
    return (
        type ===
        "0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::organization::Package"
    )
}

export interface PackageFields {
    id: ObjectId
    packageId: ObjectId
}

export class Package {
    static readonly $typeName =
        "0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::organization::Package"
    static readonly $numTypeParams = 0

    readonly id: ObjectId
    readonly packageId: ObjectId

    constructor(fields: PackageFields) {
        this.id = fields.id
        this.packageId = fields.packageId
    }

    static fromFields(fields: Record<string, any>): Package {
        return new Package({
            id: UID.fromFields(fields.id).id,
            packageId: ID.fromFields(fields.package_id).bytes,
        })
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): Package {
        if (!isPackage(item.type)) {
            throw new Error("not a Package type")
        }
        return new Package({ id: item.fields.id.id, packageId: item.fields.package_id })
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): Package {
        return Package.fromFields(bcs.de([Package.$typeName], data, encoding))
    }

    static fromSuiParsedData(content: SuiParsedData) {
        if (content.dataType !== "moveObject") {
            throw new Error("not an object")
        }
        if (!isPackage(content.type)) {
            throw new Error(`object at ${content.fields.id} is not a Package object`)
        }
        return Package.fromFieldsWithTypes(content)
    }

    static async fetch(provider: JsonRpcProvider, id: ObjectId): Promise<Package> {
        const res = await provider.getObject({ id, options: { showContent: true } })
        if (res.error) {
            throw new Error(`error fetching Package object at id ${id}: ${res.error.code}`)
        }
        if (res.data?.content?.dataType !== "moveObject" || !isPackage(res.data.content.type)) {
            throw new Error(`object at id ${id} is not a Package object`)
        }
        return Package.fromFieldsWithTypes(res.data.content)
    }
}

/* ============================== Key =============================== */

bcs.registerStructType(
    "0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::organization::Key",
    {
        dummy_field: `bool`,
    }
)

export function isKey(type: Type): boolean {
    return (
        type ===
        "0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::organization::Key"
    )
}

export interface KeyFields {
    dummyField: boolean
}

export class Key {
    static readonly $typeName =
        "0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::organization::Key"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): Key {
        return new Key(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): Key {
        if (!isKey(item.type)) {
            throw new Error("not a Key type")
        }
        return new Key(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): Key {
        return Key.fromFields(bcs.de([Key.$typeName], data, encoding))
    }
}

/* ============================== ADD_PACKAGE =============================== */

bcs.registerStructType(
    "0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::organization::ADD_PACKAGE",
    {
        dummy_field: `bool`,
    }
)

export function isADD_PACKAGE(type: Type): boolean {
    return (
        type ===
        "0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::organization::ADD_PACKAGE"
    )
}

export interface ADD_PACKAGEFields {
    dummyField: boolean
}

export class ADD_PACKAGE {
    static readonly $typeName =
        "0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::organization::ADD_PACKAGE"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ADD_PACKAGE {
        return new ADD_PACKAGE(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ADD_PACKAGE {
        if (!isADD_PACKAGE(item.type)) {
            throw new Error("not a ADD_PACKAGE type")
        }
        return new ADD_PACKAGE(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ADD_PACKAGE {
        return ADD_PACKAGE.fromFields(bcs.de([ADD_PACKAGE.$typeName], data, encoding))
    }
}

/* ============================== ENDORSE =============================== */

bcs.registerStructType(
    "0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::organization::ENDORSE",
    {
        dummy_field: `bool`,
    }
)

export function isENDORSE(type: Type): boolean {
    return (
        type ===
        "0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::organization::ENDORSE"
    )
}

export interface ENDORSEFields {
    dummyField: boolean
}

export class ENDORSE {
    static readonly $typeName =
        "0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::organization::ENDORSE"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): ENDORSE {
        return new ENDORSE(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ENDORSE {
        if (!isENDORSE(item.type)) {
            throw new Error("not a ENDORSE type")
        }
        return new ENDORSE(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ENDORSE {
        return ENDORSE.fromFields(bcs.de([ENDORSE.$typeName], data, encoding))
    }
}

/* ============================== Endorsement =============================== */

bcs.registerStructType(
    "0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::organization::Endorsement",
    {
        from: `address`,
    }
)

export function isEndorsement(type: Type): boolean {
    return (
        type ===
        "0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::organization::Endorsement"
    )
}

export interface EndorsementFields {
    from: string
}

export class Endorsement {
    static readonly $typeName =
        "0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::organization::Endorsement"
    static readonly $numTypeParams = 0

    readonly from: string

    constructor(from: string) {
        this.from = from
    }

    static fromFields(fields: Record<string, any>): Endorsement {
        return new Endorsement(`0x${fields.from}`)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): Endorsement {
        if (!isEndorsement(item.type)) {
            throw new Error("not a Endorsement type")
        }
        return new Endorsement(`0x${item.fields.from}`)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): Endorsement {
        return Endorsement.fromFields(bcs.de([Endorsement.$typeName], data, encoding))
    }
}

/* ============================== Organization =============================== */

bcs.registerStructType(
    "0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::organization::Organization",
    {
        id: `0x2::object::UID`,
        packages: `vector<0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::organization::Package>`,
        rbac: `0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::rbac::RBAC`,
    }
)

export function isOrganization(type: Type): boolean {
    return (
        type ===
        "0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::organization::Organization"
    )
}

export interface OrganizationFields {
    id: ObjectId
    packages: Array<Package>
    rbac: RBAC
}

export class Organization {
    static readonly $typeName =
        "0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::organization::Organization"
    static readonly $numTypeParams = 0

    readonly id: ObjectId
    readonly packages: Array<Package>
    readonly rbac: RBAC

    constructor(fields: OrganizationFields) {
        this.id = fields.id
        this.packages = fields.packages
        this.rbac = fields.rbac
    }

    static fromFields(fields: Record<string, any>): Organization {
        return new Organization({
            id: UID.fromFields(fields.id).id,
            packages: fields.packages.map((item: any) => Package.fromFields(item)),
            rbac: RBAC.fromFields(fields.rbac),
        })
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): Organization {
        if (!isOrganization(item.type)) {
            throw new Error("not a Organization type")
        }
        return new Organization({
            id: item.fields.id.id,
            packages: item.fields.packages.map((item: any) => Package.fromFieldsWithTypes(item)),
            rbac: RBAC.fromFieldsWithTypes(item.fields.rbac),
        })
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): Organization {
        return Organization.fromFields(bcs.de([Organization.$typeName], data, encoding))
    }

    static fromSuiParsedData(content: SuiParsedData) {
        if (content.dataType !== "moveObject") {
            throw new Error("not an object")
        }
        if (!isOrganization(content.type)) {
            throw new Error(`object at ${content.fields.id} is not a Organization object`)
        }
        return Organization.fromFieldsWithTypes(content)
    }

    static async fetch(provider: JsonRpcProvider, id: ObjectId): Promise<Organization> {
        const res = await provider.getObject({ id, options: { showContent: true } })
        if (res.error) {
            throw new Error(`error fetching Organization object at id ${id}: ${res.error.code}`)
        }
        if (
            res.data?.content?.dataType !== "moveObject" ||
            !isOrganization(res.data.content.type)
        ) {
            throw new Error(`object at id ${id} is not a Organization object`)
        }
        return Organization.fromFieldsWithTypes(res.data.content)
    }
}

/* ============================== REMOVE_PACKAGE =============================== */

bcs.registerStructType(
    "0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::organization::REMOVE_PACKAGE",
    {
        dummy_field: `bool`,
    }
)

export function isREMOVE_PACKAGE(type: Type): boolean {
    return (
        type ===
        "0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::organization::REMOVE_PACKAGE"
    )
}

export interface REMOVE_PACKAGEFields {
    dummyField: boolean
}

export class REMOVE_PACKAGE {
    static readonly $typeName =
        "0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::organization::REMOVE_PACKAGE"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): REMOVE_PACKAGE {
        return new REMOVE_PACKAGE(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): REMOVE_PACKAGE {
        if (!isREMOVE_PACKAGE(item.type)) {
            throw new Error("not a REMOVE_PACKAGE type")
        }
        return new REMOVE_PACKAGE(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): REMOVE_PACKAGE {
        return REMOVE_PACKAGE.fromFields(bcs.de([REMOVE_PACKAGE.$typeName], data, encoding))
    }
}
