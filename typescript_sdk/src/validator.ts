import { BCS } from "@mysten/bcs";
import {
  object,
  integer,
  bigint,
  string,
  boolean,
  number,
  array,
  union,
  any,
  Struct,
  assert
} from "superstruct";

type MoveToJSTypes = {
  address: Uint8Array;
  bool: boolean;
  id: Uint8Array;
  u8: number;
  u16: number;
  u32: number;
  u64: bigint;
  u128: bigint;
  u256: bigint;
  ascii: string;
  utf8: string;
  "vector<u8>": number[];
  "Option<ascii>": { some: string } | { none: null };
};

export type JSTypes<T extends Record<string, keyof MoveToJSTypes>> = {
  -readonly [K in keyof T]: MoveToJSTypes[T[K]];
};

export class Validator {
    schema: Record<string, string>

    constructor(schema: Record<string, string>){
        this.schema = schema;
    }

  readonly moveToStruct: Record<string, any> = {
    address: array(number()),
    bool: boolean(),
    id: array(number()),
    u8: integer(),
    u16: integer(),
    u32: integer(),
    u64: bigint(),
    u128: bigint(),
    u256: bigint(),
    ascii: string(),
    utf8: string(),
    "vector<u8>": array(integer()),
    "Option<ascii>": union([
      object({ none: any() }),
      object({ some: string() }),
    ]),
  };


  structValidator(): Struct<{ [x: string]: any }, Record<string, any>> {
    const dynamicStruct: Record<string, any> = {};
    Object.keys(this.schema).map((key) => {
      dynamicStruct[key] = this.moveToStruct[this.schema[key]];
    });
    return object(dynamicStruct);
  }

  public check() {
    const validator = this.structValidator(); 
    assert(this.schema, validator);
  }

}
