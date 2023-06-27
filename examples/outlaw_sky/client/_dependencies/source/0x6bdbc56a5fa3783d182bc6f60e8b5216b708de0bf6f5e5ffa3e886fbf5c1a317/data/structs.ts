import { bcsSource as bcs } from "../../../../_framework/bcs";
import { FieldsWithTypes, Type } from "../../../../_framework/util";
import { Option } from "../../0x1/option/structs";
import { String } from "../../0x1/string/structs";
import { Encoding } from "@mysten/bcs";
import { ObjectId } from "@mysten/sui.js";

/* ============================== Key =============================== */

bcs.registerStructType(
  "0x6bdbc56a5fa3783d182bc6f60e8b5216b708de0bf6f5e5ffa3e886fbf5c1a317::data::Key",
  {
    namespace: `0x1::option::Option<0x2::object::ID>`,
    key: `0x1::string::String`,
  }
);

export function isKey(type: Type): boolean {
  return (
    type ===
    "0x6bdbc56a5fa3783d182bc6f60e8b5216b708de0bf6f5e5ffa3e886fbf5c1a317::data::Key"
  );
}

export interface KeyFields {
  namespace: ObjectId | null;
  key: string;
}

export class Key {
  static readonly $typeName =
    "0x6bdbc56a5fa3783d182bc6f60e8b5216b708de0bf6f5e5ffa3e886fbf5c1a317::data::Key";
  static readonly $numTypeParams = 0;

  readonly namespace: ObjectId | null;
  readonly key: string;

  constructor(fields: KeyFields) {
    this.namespace = fields.namespace;
    this.key = fields.key;
  }

  static fromFields(fields: Record<string, any>): Key {
    return new Key({
      namespace:
        Option.fromFields<ObjectId>(`0x2::object::ID`, fields.namespace)
          .vec[0] || null,
      key: new TextDecoder()
        .decode(Uint8Array.from(String.fromFields(fields.key).bytes))
        .toString(),
    });
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): Key {
    if (!isKey(item.type)) {
      throw new Error("not a Key type");
    }
    return new Key({
      namespace:
        item.fields.namespace !== null
          ? Option.fromFieldsWithTypes<ObjectId>({
              type: "0x1::option::Option<" + `0x2::object::ID` + ">",
              fields: { vec: [item.fields.namespace] },
            }).vec[0]
          : null,
      key: item.fields.key,
    });
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): Key {
    return Key.fromFields(bcs.de([Key.$typeName], data, encoding));
  }
}

/* ============================== WRITE =============================== */

bcs.registerStructType(
  "0x6bdbc56a5fa3783d182bc6f60e8b5216b708de0bf6f5e5ffa3e886fbf5c1a317::data::WRITE",
  {
    dummy_field: `bool`,
  }
);

export function isWRITE(type: Type): boolean {
  return (
    type ===
    "0x6bdbc56a5fa3783d182bc6f60e8b5216b708de0bf6f5e5ffa3e886fbf5c1a317::data::WRITE"
  );
}

export interface WRITEFields {
  dummyField: boolean;
}

export class WRITE {
  static readonly $typeName =
    "0x6bdbc56a5fa3783d182bc6f60e8b5216b708de0bf6f5e5ffa3e886fbf5c1a317::data::WRITE";
  static readonly $numTypeParams = 0;

  readonly dummyField: boolean;

  constructor(dummyField: boolean) {
    this.dummyField = dummyField;
  }

  static fromFields(fields: Record<string, any>): WRITE {
    return new WRITE(fields.dummy_field);
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): WRITE {
    if (!isWRITE(item.type)) {
      throw new Error("not a WRITE type");
    }
    return new WRITE(item.fields.dummy_field);
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): WRITE {
    return WRITE.fromFields(bcs.de([WRITE.$typeName], data, encoding));
  }
}
