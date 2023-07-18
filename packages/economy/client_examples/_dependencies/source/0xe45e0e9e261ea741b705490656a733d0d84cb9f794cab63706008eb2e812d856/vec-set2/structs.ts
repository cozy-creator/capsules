import { bcsSource as bcs } from "../../../../_framework/bcs";
import { initLoaderIfNeeded } from "../../../../_framework/init-source";
import { structClassLoaderSource } from "../../../../_framework/loader";
import {
  FieldsWithTypes,
  Type,
  parseTypeName,
} from "../../../../_framework/util";
import { Encoding } from "@mysten/bcs";

/* ============================== VecSet =============================== */

bcs.registerStructType(
  "0xe45e0e9e261ea741b705490656a733d0d84cb9f794cab63706008eb2e812d856::vec_set2::VecSet<K>",
  {
    contents: `vector<K>`,
  },
);

export function isVecSet(type: Type): boolean {
  return type.startsWith(
    "0xe45e0e9e261ea741b705490656a733d0d84cb9f794cab63706008eb2e812d856::vec_set2::VecSet<",
  );
}

export interface VecSetFields<K> {
  contents: Array<K>;
}

export class VecSet<K> {
  static readonly $typeName =
    "0xe45e0e9e261ea741b705490656a733d0d84cb9f794cab63706008eb2e812d856::vec_set2::VecSet";
  static readonly $numTypeParams = 1;

  readonly $typeArg: Type;

  readonly contents: Array<K>;

  constructor(typeArg: Type, contents: Array<K>) {
    this.$typeArg = typeArg;

    this.contents = contents;
  }

  static fromFields<K>(typeArg: Type, fields: Record<string, any>): VecSet<K> {
    initLoaderIfNeeded();

    return new VecSet(
      typeArg,
      fields.contents.map((item: any) =>
        structClassLoaderSource.fromFields(typeArg, item),
      ),
    );
  }

  static fromFieldsWithTypes<K>(item: FieldsWithTypes): VecSet<K> {
    initLoaderIfNeeded();

    if (!isVecSet(item.type)) {
      throw new Error("not a VecSet type");
    }
    const { typeArgs } = parseTypeName(item.type);

    return new VecSet(
      typeArgs[0],
      item.fields.contents.map((item: any) =>
        structClassLoaderSource.fromFieldsWithTypes(typeArgs[0], item),
      ),
    );
  }

  static fromBcs<K>(
    typeArg: Type,
    data: Uint8Array | string,
    encoding?: Encoding,
  ): VecSet<K> {
    return VecSet.fromFields(
      typeArg,
      bcs.de([VecSet.$typeName, typeArg], data, encoding),
    );
  }
}
