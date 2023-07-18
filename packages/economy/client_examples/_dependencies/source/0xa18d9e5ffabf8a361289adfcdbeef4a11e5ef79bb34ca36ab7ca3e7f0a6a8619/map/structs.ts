import { bcsSource as bcs } from "../../../../_framework/bcs";
import { initLoaderIfNeeded } from "../../../../_framework/init-source";
import { structClassLoaderSource } from "../../../../_framework/loader";
import {
  FieldsWithTypes,
  Type,
  parseTypeName,
} from "../../../../_framework/util";
import { ID, UID } from "../../0x2/object/structs";
import { Encoding } from "@mysten/bcs";
import { JsonRpcProvider, ObjectId, SuiParsedData } from "@mysten/sui.js";

/* ============================== Iter =============================== */

bcs.registerStructType(
  "0xa18d9e5ffabf8a361289adfcdbeef4a11e5ef79bb34ca36ab7ca3e7f0a6a8619::map::Iter<Key>",
  {
    for: `0x2::object::ID`,
    keys: `vector<Key>`,
  },
);

export function isIter(type: Type): boolean {
  return type.startsWith(
    "0xa18d9e5ffabf8a361289adfcdbeef4a11e5ef79bb34ca36ab7ca3e7f0a6a8619::map::Iter<",
  );
}

export interface IterFields<Key> {
  for: ObjectId;
  keys: Array<Key>;
}

export class Iter<Key> {
  static readonly $typeName =
    "0xa18d9e5ffabf8a361289adfcdbeef4a11e5ef79bb34ca36ab7ca3e7f0a6a8619::map::Iter";
  static readonly $numTypeParams = 1;

  readonly $typeArg: Type;

  readonly for: ObjectId;
  readonly keys: Array<Key>;

  constructor(typeArg: Type, fields: IterFields<Key>) {
    this.$typeArg = typeArg;

    this.for = fields.for;
    this.keys = fields.keys;
  }

  static fromFields<Key>(
    typeArg: Type,
    fields: Record<string, any>,
  ): Iter<Key> {
    initLoaderIfNeeded();

    return new Iter(typeArg, {
      for: ID.fromFields(fields.for).bytes,
      keys: fields.keys.map((item: any) =>
        structClassLoaderSource.fromFields(typeArg, item),
      ),
    });
  }

  static fromFieldsWithTypes<Key>(item: FieldsWithTypes): Iter<Key> {
    initLoaderIfNeeded();

    if (!isIter(item.type)) {
      throw new Error("not a Iter type");
    }
    const { typeArgs } = parseTypeName(item.type);

    return new Iter(typeArgs[0], {
      for: item.fields.for,
      keys: item.fields.keys.map((item: any) =>
        structClassLoaderSource.fromFieldsWithTypes(typeArgs[0], item),
      ),
    });
  }

  static fromBcs<Key>(
    typeArg: Type,
    data: Uint8Array | string,
    encoding?: Encoding,
  ): Iter<Key> {
    return Iter.fromFields(
      typeArg,
      bcs.de([Iter.$typeName, typeArg], data, encoding),
    );
  }
}

/* ============================== Map =============================== */

bcs.registerStructType(
  "0xa18d9e5ffabf8a361289adfcdbeef4a11e5ef79bb34ca36ab7ca3e7f0a6a8619::map::Map<Key, Value>",
  {
    id: `0x2::object::UID`,
    index: `vector<Key>`,
  },
);

export function isMap(type: Type): boolean {
  return type.startsWith(
    "0xa18d9e5ffabf8a361289adfcdbeef4a11e5ef79bb34ca36ab7ca3e7f0a6a8619::map::Map<",
  );
}

export interface MapFields<Key> {
  id: ObjectId;
  index: Array<Key>;
}

export class Map<Key> {
  static readonly $typeName =
    "0xa18d9e5ffabf8a361289adfcdbeef4a11e5ef79bb34ca36ab7ca3e7f0a6a8619::map::Map";
  static readonly $numTypeParams = 2;

  readonly $typeArgs: [Type, Type];

  readonly id: ObjectId;
  readonly index: Array<Key>;

  constructor(typeArgs: [Type, Type], fields: MapFields<Key>) {
    this.$typeArgs = typeArgs;

    this.id = fields.id;
    this.index = fields.index;
  }

  static fromFields<Key>(
    typeArgs: [Type, Type],
    fields: Record<string, any>,
  ): Map<Key> {
    initLoaderIfNeeded();

    return new Map(typeArgs, {
      id: UID.fromFields(fields.id).id,
      index: fields.index.map((item: any) =>
        structClassLoaderSource.fromFields(typeArgs[0], item),
      ),
    });
  }

  static fromFieldsWithTypes<Key>(item: FieldsWithTypes): Map<Key> {
    initLoaderIfNeeded();

    if (!isMap(item.type)) {
      throw new Error("not a Map type");
    }
    const { typeArgs } = parseTypeName(item.type);

    return new Map([typeArgs[0], typeArgs[1]], {
      id: item.fields.id.id,
      index: item.fields.index.map((item: any) =>
        structClassLoaderSource.fromFieldsWithTypes(typeArgs[0], item),
      ),
    });
  }

  static fromBcs<Key>(
    typeArgs: [Type, Type],
    data: Uint8Array | string,
    encoding?: Encoding,
  ): Map<Key> {
    return Map.fromFields(
      typeArgs,
      bcs.de([Map.$typeName, ...typeArgs], data, encoding),
    );
  }

  static fromSuiParsedData(content: SuiParsedData) {
    if (content.dataType !== "moveObject") {
      throw new Error("not an object");
    }
    if (!isMap(content.type)) {
      throw new Error(`object at ${content.fields.id} is not a Map object`);
    }
    return Map.fromFieldsWithTypes(content);
  }

  static async fetch<Key>(
    provider: JsonRpcProvider,
    id: ObjectId,
  ): Promise<Map<Key>> {
    const res = await provider.getObject({
      id,
      options: { showContent: true },
    });
    if (res.error) {
      throw new Error(
        `error fetching Map object at id ${id}: ${res.error.code}`,
      );
    }
    if (
      res.data?.content?.dataType !== "moveObject" ||
      !isMap(res.data.content.type)
    ) {
      throw new Error(`object at id ${id} is not a Map object`);
    }
    return Map.fromFieldsWithTypes(res.data.content);
  }
}
