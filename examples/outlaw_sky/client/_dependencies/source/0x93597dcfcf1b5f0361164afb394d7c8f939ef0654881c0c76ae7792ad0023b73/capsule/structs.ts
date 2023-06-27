import { bcsSource as bcs } from "../../../../_framework/bcs";
import { initLoaderIfNeeded } from "../../../../_framework/init-source";
import {
  FieldsWithTypes,
  Type,
  parseTypeName,
} from "../../../../_framework/util";
import { Option } from "../../0x1/option/structs";
import { UID } from "../../0x2/object/structs";
import { Encoding } from "@mysten/bcs";
import { JsonRpcProvider, ObjectId, SuiParsedData } from "@mysten/sui.js";

/* ============================== Witness =============================== */

bcs.registerStructType(
  "0x93597dcfcf1b5f0361164afb394d7c8f939ef0654881c0c76ae7792ad0023b73::capsule::Witness",
  {
    dummy_field: `bool`,
  }
);

export function isWitness(type: Type): boolean {
  return (
    type ===
    "0x93597dcfcf1b5f0361164afb394d7c8f939ef0654881c0c76ae7792ad0023b73::capsule::Witness"
  );
}

export interface WitnessFields {
  dummyField: boolean;
}

export class Witness {
  static readonly $typeName =
    "0x93597dcfcf1b5f0361164afb394d7c8f939ef0654881c0c76ae7792ad0023b73::capsule::Witness";
  static readonly $numTypeParams = 0;

  readonly dummyField: boolean;

  constructor(dummyField: boolean) {
    this.dummyField = dummyField;
  }

  static fromFields(fields: Record<string, any>): Witness {
    return new Witness(fields.dummy_field);
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): Witness {
    if (!isWitness(item.type)) {
      throw new Error("not a Witness type");
    }
    return new Witness(item.fields.dummy_field);
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): Witness {
    return Witness.fromFields(bcs.de([Witness.$typeName], data, encoding));
  }
}

/* ============================== Key =============================== */

bcs.registerStructType(
  "0x93597dcfcf1b5f0361164afb394d7c8f939ef0654881c0c76ae7792ad0023b73::capsule::Key",
  {
    dummy_field: `bool`,
  }
);

export function isKey(type: Type): boolean {
  return (
    type ===
    "0x93597dcfcf1b5f0361164afb394d7c8f939ef0654881c0c76ae7792ad0023b73::capsule::Key"
  );
}

export interface KeyFields {
  dummyField: boolean;
}

export class Key {
  static readonly $typeName =
    "0x93597dcfcf1b5f0361164afb394d7c8f939ef0654881c0c76ae7792ad0023b73::capsule::Key";
  static readonly $numTypeParams = 0;

  readonly dummyField: boolean;

  constructor(dummyField: boolean) {
    this.dummyField = dummyField;
  }

  static fromFields(fields: Record<string, any>): Key {
    return new Key(fields.dummy_field);
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): Key {
    if (!isKey(item.type)) {
      throw new Error("not a Key type");
    }
    return new Key(item.fields.dummy_field);
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): Key {
    return Key.fromFields(bcs.de([Key.$typeName], data, encoding));
  }
}

/* ============================== Capsule =============================== */

bcs.registerStructType(
  "0x93597dcfcf1b5f0361164afb394d7c8f939ef0654881c0c76ae7792ad0023b73::capsule::Capsule<T>",
  {
    id: `0x2::object::UID`,
    contents: `0x1::option::Option<T>`,
  }
);

export function isCapsule(type: Type): boolean {
  return type.startsWith(
    "0x93597dcfcf1b5f0361164afb394d7c8f939ef0654881c0c76ae7792ad0023b73::capsule::Capsule<"
  );
}

export interface CapsuleFields<T> {
  id: ObjectId;
  contents: T | null;
}

export class Capsule<T> {
  static readonly $typeName =
    "0x93597dcfcf1b5f0361164afb394d7c8f939ef0654881c0c76ae7792ad0023b73::capsule::Capsule";
  static readonly $numTypeParams = 1;

  readonly $typeArg: Type;

  readonly id: ObjectId;
  readonly contents: T | null;

  constructor(typeArg: Type, fields: CapsuleFields<T>) {
    this.$typeArg = typeArg;

    this.id = fields.id;
    this.contents = fields.contents;
  }

  static fromFields<T>(typeArg: Type, fields: Record<string, any>): Capsule<T> {
    initLoaderIfNeeded();

    return new Capsule(typeArg, {
      id: UID.fromFields(fields.id).id,
      contents:
        Option.fromFields<T>(`${typeArg}`, fields.contents).vec[0] || null,
    });
  }

  static fromFieldsWithTypes<T>(item: FieldsWithTypes): Capsule<T> {
    initLoaderIfNeeded();

    if (!isCapsule(item.type)) {
      throw new Error("not a Capsule type");
    }
    const { typeArgs } = parseTypeName(item.type);

    return new Capsule(typeArgs[0], {
      id: item.fields.id.id,
      contents:
        item.fields.contents !== null
          ? Option.fromFieldsWithTypes<T>({
              type: "0x1::option::Option<" + `${typeArgs[0]}` + ">",
              fields: { vec: [item.fields.contents] },
            }).vec[0]
          : null,
    });
  }

  static fromBcs<T>(
    typeArg: Type,
    data: Uint8Array | string,
    encoding?: Encoding
  ): Capsule<T> {
    return Capsule.fromFields(
      typeArg,
      bcs.de([Capsule.$typeName, typeArg], data, encoding)
    );
  }

  static fromSuiParsedData(content: SuiParsedData) {
    if (content.dataType !== "moveObject") {
      throw new Error("not an object");
    }
    if (!isCapsule(content.type)) {
      throw new Error(`object at ${content.fields.id} is not a Capsule object`);
    }
    return Capsule.fromFieldsWithTypes(content);
  }

  static async fetch<T>(
    provider: JsonRpcProvider,
    id: ObjectId
  ): Promise<Capsule<T>> {
    const res = await provider.getObject({
      id,
      options: { showContent: true },
    });
    if (res.error) {
      throw new Error(
        `error fetching Capsule object at id ${id}: ${res.error.code}`
      );
    }
    if (
      res.data?.content?.dataType !== "moveObject" ||
      !isCapsule(res.data.content.type)
    ) {
      throw new Error(`object at id ${id} is not a Capsule object`);
    }
    return Capsule.fromFieldsWithTypes(res.data.content);
  }
}
