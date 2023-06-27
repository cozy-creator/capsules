import { bcsSource as bcs } from "../../../../_framework/bcs";
import { initLoaderIfNeeded } from "../../../../_framework/init-source";
import { structClassLoaderSource } from "../../../../_framework/loader";
import {
  FieldsWithTypes,
  Type,
  parseTypeName,
} from "../../../../_framework/util";
import { Encoding } from "@mysten/bcs";

/* ============================== Out =============================== */

bcs.registerStructType(
  "0x390d9fbd00f96974df331c15686ec661a52aae03b9fc15e5a10e6dec65d594c::vector2::Out<T>",
  {
    vec: `vector<T>`,
  }
);

export function isOut(type: Type): boolean {
  return type.startsWith(
    "0x390d9fbd00f96974df331c15686ec661a52aae03b9fc15e5a10e6dec65d594c::vector2::Out<"
  );
}

export interface OutFields<T> {
  vec: Array<T>;
}

export class Out<T> {
  static readonly $typeName =
    "0x390d9fbd00f96974df331c15686ec661a52aae03b9fc15e5a10e6dec65d594c::vector2::Out";
  static readonly $numTypeParams = 1;

  readonly $typeArg: Type;

  readonly vec: Array<T>;

  constructor(typeArg: Type, vec: Array<T>) {
    this.$typeArg = typeArg;

    this.vec = vec;
  }

  static fromFields<T>(typeArg: Type, fields: Record<string, any>): Out<T> {
    initLoaderIfNeeded();

    return new Out(
      typeArg,
      fields.vec.map((item: any) =>
        structClassLoaderSource.fromFields(typeArg, item)
      )
    );
  }

  static fromFieldsWithTypes<T>(item: FieldsWithTypes): Out<T> {
    initLoaderIfNeeded();

    if (!isOut(item.type)) {
      throw new Error("not a Out type");
    }
    const { typeArgs } = parseTypeName(item.type);

    return new Out(
      typeArgs[0],
      item.fields.vec.map((item: any) =>
        structClassLoaderSource.fromFieldsWithTypes(typeArgs[0], item)
      )
    );
  }

  static fromBcs<T>(
    typeArg: Type,
    data: Uint8Array | string,
    encoding?: Encoding
  ): Out<T> {
    return Out.fromFields(
      typeArg,
      bcs.de([Out.$typeName, typeArg], data, encoding)
    );
  }
}
