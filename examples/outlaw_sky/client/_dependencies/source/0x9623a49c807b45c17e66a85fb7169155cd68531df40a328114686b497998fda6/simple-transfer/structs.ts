import { bcsSource as bcs } from "../../../../_framework/bcs"
import { FieldsWithTypes, Type } from "../../../../_framework/util"
import { Encoding } from "@mysten/bcs"

/* ============================== SimpleTransfer =============================== */

bcs.registerStructType(
    "0x9623a49c807b45c17e66a85fb7169155cd68531df40a328114686b497998fda6::simple_transfer::SimpleTransfer",
    {
        dummy_field: `bool`,
    }
)

export function isSimpleTransfer(type: Type): boolean {
    return (
        type ===
        "0x9623a49c807b45c17e66a85fb7169155cd68531df40a328114686b497998fda6::simple_transfer::SimpleTransfer"
    )
}

export interface SimpleTransferFields {
    dummyField: boolean
}

export class SimpleTransfer {
    static readonly $typeName =
        "0x9623a49c807b45c17e66a85fb7169155cd68531df40a328114686b497998fda6::simple_transfer::SimpleTransfer"
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
