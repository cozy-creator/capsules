import { bcsSource as bcs } from "../../../../_framework/bcs"
import { FieldsWithTypes, Type } from "../../../../_framework/util"
import { Encoding } from "@mysten/bcs"

/* ============================== SimpleTransfer =============================== */

bcs.registerStructType(
    "0xa2cdbe6407e7c2c6e06611e8edb41dc0a23360184f33974015257481ae3541df::simple_transfer::SimpleTransfer",
    {
        dummy_field: `bool`,
    }
)

export function isSimpleTransfer(type: Type): boolean {
    return (
        type ===
        "0xa2cdbe6407e7c2c6e06611e8edb41dc0a23360184f33974015257481ae3541df::simple_transfer::SimpleTransfer"
    )
}

export interface SimpleTransferFields {
    dummyField: boolean
}

export class SimpleTransfer {
    static readonly $typeName =
        "0xa2cdbe6407e7c2c6e06611e8edb41dc0a23360184f33974015257481ae3541df::simple_transfer::SimpleTransfer"
    static readonly $numTypeParams = 0

    readonly dummyField: boolean

    constructor(dummyField: boolean) {
        this.dummyField = dummyField
    }

    static fromFields(fields: Record<string, any>): SimpleTransfer {
        return new SimpleTransfer(fields.dummy_field)
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): SimpleTransfer {
        if (!isSimpleTransfer(item.type)) {
            throw new Error("not a SimpleTransfer type")
        }
        return new SimpleTransfer(item.fields.dummy_field)
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): SimpleTransfer {
        return SimpleTransfer.fromFields(bcs.de([SimpleTransfer.$typeName], data, encoding))
    }
}
