import { String } from "../../_dependencies/source/0x1/string/structs";
import { bcsSource as bcs } from "../../_framework/bcs";
import { FieldsWithTypes, Type } from "../../_framework/util";
import { ID } from "../../sui/object/structs";
import { Encoding } from "@mysten/bcs";
import { ObjectId } from "@mysten/sui.js";

/* ============================== PayMemo =============================== */

bcs.registerStructType(
  "0x77e53a48851512fe5707346cf90f85ae0c46b6b527b0fa04935940b0e2f38b42::pay_memo::PayMemo",
  {
    reference_id: `0x2::object::ID`,
    merchant: `0x1::string::String`,
    description: `0x1::string::String`,
  },
);

export function isPayMemo(type: Type): boolean {
  return (
    type ===
    "0x77e53a48851512fe5707346cf90f85ae0c46b6b527b0fa04935940b0e2f38b42::pay_memo::PayMemo"
  );
}

export interface PayMemoFields {
  referenceId: ObjectId;
  merchant: string;
  description: string;
}

export class PayMemo {
  static readonly $typeName =
    "0x77e53a48851512fe5707346cf90f85ae0c46b6b527b0fa04935940b0e2f38b42::pay_memo::PayMemo";
  static readonly $numTypeParams = 0;

  readonly referenceId: ObjectId;
  readonly merchant: string;
  readonly description: string;

  constructor(fields: PayMemoFields) {
    this.referenceId = fields.referenceId;
    this.merchant = fields.merchant;
    this.description = fields.description;
  }

  static fromFields(fields: Record<string, any>): PayMemo {
    return new PayMemo({
      referenceId: ID.fromFields(fields.reference_id).bytes,
      merchant: new TextDecoder()
        .decode(Uint8Array.from(String.fromFields(fields.merchant).bytes))
        .toString(),
      description: new TextDecoder()
        .decode(Uint8Array.from(String.fromFields(fields.description).bytes))
        .toString(),
    });
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): PayMemo {
    if (!isPayMemo(item.type)) {
      throw new Error("not a PayMemo type");
    }
    return new PayMemo({
      referenceId: item.fields.reference_id,
      merchant: item.fields.merchant,
      description: item.fields.description,
    });
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): PayMemo {
    return PayMemo.fromFields(bcs.de([PayMemo.$typeName], data, encoding));
  }
}
