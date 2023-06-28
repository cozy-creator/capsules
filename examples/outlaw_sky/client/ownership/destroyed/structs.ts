import { bcsSource as bcs } from "../../_framework/bcs"
import { FieldsWithTypes, Type } from "../../_framework/util"
import { Encoding } from "@mysten/bcs"

/* ============================== IsDestroyed =============================== */

bcs.registerStructType(
    "0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::destroyed::IsDestroyed",
    {
        dummy_field: `bool`,
    }
)

export function isIsDestroyed(type: Type): boolean {
    return (
        type ===
        "0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::destroyed::IsDestroyed"
    )
}

export interface IsDestroyedFields {
    dummyField: boolean
}

export class IsDestroyed {
    static readonly $typeName =
        "0x98eff0617dfece5a417af4e2d2338afdfc5124e35a337c530161e8f3d7ac3e96::destroyed::IsDestroyed"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): IsDestroyed {
        return new IsDestroyed(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): IsDestroyed {
        if (!isIsDestroyed(item.type)) {
            throw new Error("not a IsDestroyed type")
        }
        return new IsDestroyed(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): IsDestroyed {
        return IsDestroyed.fromFields(bcs.de([IsDestroyed.$typeName], data, encoding))
    }
}
