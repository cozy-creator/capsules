import { bcsSource as bcs } from "../../../../_framework/bcs";
import { FieldsWithTypes, Type } from "../../../../_framework/util";
import { Option } from "../../0x1/option/structs";
import { Encoding } from "@mysten/bcs";
import { ObjectId } from "@mysten/sui.js";

/* ============================== Key =============================== */

bcs.registerStructType(
  "0xa17ae8f9e52566906c045e034b5e3f1b1ca88dc3aa8ce72e829e35aa46e5e77e::schema::Key",
  {
    namespace: `0x1::option::Option<0x2::object::ID>`,
  }
);

export function isKey(type: Type): boolean {
  return (
    type ===
    "0xa17ae8f9e52566906c045e034b5e3f1b1ca88dc3aa8ce72e829e35aa46e5e77e::schema::Key"
  );
}

export interface KeyFields {
  namespace: ObjectId | null;
}

export class Key {
  static readonly $typeName =
    "0xa17ae8f9e52566906c045e034b5e3f1b1ca88dc3aa8ce72e829e35aa46e5e77e::schema::Key";
  static readonly $numTypeParams = 0;

  readonly namespace: ObjectId | null;

  constructor(namespace: ObjectId | null) {
    this.namespace = namespace;
  }

  static fromFields(fields: Record<string, any>): Key {
    return new Key(
      Option.fromFields<ObjectId>(`0x2::object::ID`, fields.namespace).vec[0] ||
        null
    );
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): Key {
    if (!isKey(item.type)) {
      throw new Error("not a Key type");
    }
    return new Key(
      item.fields.namespace !== null
        ? Option.fromFieldsWithTypes<ObjectId>({
            type: "0x1::option::Option<" + `0x2::object::ID` + ">",
            fields: { vec: [item.fields.namespace] },
          }).vec[0]
        : null
    );
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): Key {
    return Key.fromFields(bcs.de([Key.$typeName], data, encoding));
  }
}
