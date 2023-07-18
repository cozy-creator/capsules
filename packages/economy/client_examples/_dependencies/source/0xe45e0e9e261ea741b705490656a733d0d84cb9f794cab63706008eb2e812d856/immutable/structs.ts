import { bcsSource as bcs } from "../../../../_framework/bcs";
import { initLoaderIfNeeded } from "../../../../_framework/init-source";
import { structClassLoaderSource } from "../../../../_framework/loader";
import {
  FieldsWithTypes,
  Type,
  parseTypeName,
} from "../../../../_framework/util";
import { UID } from "../../0x2/object/structs";
import { Encoding } from "@mysten/bcs";
import { JsonRpcProvider, ObjectId, SuiParsedData } from "@mysten/sui.js";

/* ============================== Immutable =============================== */

bcs.registerStructType(
  "0xe45e0e9e261ea741b705490656a733d0d84cb9f794cab63706008eb2e812d856::immutable::Immutable<T>",
  {
    id: `0x2::object::UID`,
    allow_read: `bool`,
    contents: `T`,
  },
);

export function isImmutable(type: Type): boolean {
  return type.startsWith(
    "0xe45e0e9e261ea741b705490656a733d0d84cb9f794cab63706008eb2e812d856::immutable::Immutable<",
  );
}

export interface ImmutableFields<T> {
  id: ObjectId;
  allowRead: boolean;
  contents: T;
}

export class Immutable<T> {
  static readonly $typeName =
    "0xe45e0e9e261ea741b705490656a733d0d84cb9f794cab63706008eb2e812d856::immutable::Immutable";
  static readonly $numTypeParams = 1;

  readonly $typeArg: Type;

  readonly id: ObjectId;
  readonly allowRead: boolean;
  readonly contents: T;

  constructor(typeArg: Type, fields: ImmutableFields<T>) {
    this.$typeArg = typeArg;

    this.id = fields.id;
    this.allowRead = fields.allowRead;
    this.contents = fields.contents;
  }

  static fromFields<T>(
    typeArg: Type,
    fields: Record<string, any>,
  ): Immutable<T> {
    initLoaderIfNeeded();

    return new Immutable(typeArg, {
      id: UID.fromFields(fields.id).id,
      allowRead: fields.allow_read,
      contents: structClassLoaderSource.fromFields(typeArg, fields.contents),
    });
  }

  static fromFieldsWithTypes<T>(item: FieldsWithTypes): Immutable<T> {
    initLoaderIfNeeded();

    if (!isImmutable(item.type)) {
      throw new Error("not a Immutable type");
    }
    const { typeArgs } = parseTypeName(item.type);

    return new Immutable(typeArgs[0], {
      id: item.fields.id.id,
      allowRead: item.fields.allow_read,
      contents: structClassLoaderSource.fromFieldsWithTypes(
        typeArgs[0],
        item.fields.contents,
      ),
    });
  }

  static fromBcs<T>(
    typeArg: Type,
    data: Uint8Array | string,
    encoding?: Encoding,
  ): Immutable<T> {
    return Immutable.fromFields(
      typeArg,
      bcs.de([Immutable.$typeName, typeArg], data, encoding),
    );
  }

  static fromSuiParsedData(content: SuiParsedData) {
    if (content.dataType !== "moveObject") {
      throw new Error("not an object");
    }
    if (!isImmutable(content.type)) {
      throw new Error(
        `object at ${content.fields.id} is not a Immutable object`,
      );
    }
    return Immutable.fromFieldsWithTypes(content);
  }

  static async fetch<T>(
    provider: JsonRpcProvider,
    id: ObjectId,
  ): Promise<Immutable<T>> {
    const res = await provider.getObject({
      id,
      options: { showContent: true },
    });
    if (res.error) {
      throw new Error(
        `error fetching Immutable object at id ${id}: ${res.error.code}`,
      );
    }
    if (
      res.data?.content?.dataType !== "moveObject" ||
      !isImmutable(res.data.content.type)
    ) {
      throw new Error(`object at id ${id} is not a Immutable object`);
    }
    return Immutable.fromFieldsWithTypes(res.data.content);
  }
}
