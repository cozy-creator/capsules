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
} from "superstruct";

export type JSTypes<T extends Record<string, keyof MoveToJSTypes>> = {
  -readonly [K in keyof T]: MoveToJSTypes[T[K]];
};

export type MoveToJSTypes = {
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
  "Option<ascii>": { none: null } | { some: string };
};

export const MoveToStruct: Record<string, any> = {
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
  "Option<ascii>": union([object({ none: any() }), object({ some: string() })]),
};

// ====== Helper Functions ======

export function moveStructValidator(
  schema: Record<string, string>
): Struct<{ [x: string]: any }, Record<string, any>> {
  const dynamicStruct: Record<string, any> = {};

  Object.keys(schema).map((key) => {
    dynamicStruct[key] = MoveToStruct[schema[key]];
  });

  return object(dynamicStruct);
}

function ser<T>(bcs: BCS, value: any, key: string): number[] {
  return Array.from(bcs.ser(key, value).toBytes());
}


export function serialize<T>(
  bcs: BCS,
  data: any,
  schema: Record<string, string>,
  onlyKeys?: string[]
): number[][] {
  const serializedData: number[][] = [];
  if (!onlyKeys) {
    for (const [key, keyType] of Object.entries(schema)) {
      const bytesArray = ser(bcs, data[key], keyType);
      serializedData.push(bytesArray);
    }
  } else {
    onlyKeys.forEach((key) => {
      const bytesArray = ser(bcs, data[key], schema[key]);
      serializedData.push(bytesArray);
    });
  }
  return serializedData;
}


export function deserialize<T>(
  bcs: BCS,
  bytesArray: Uint8Array[],
  schema: Record<string, string>,
  keys?:string[]
): Record<string, string> | null{
  let deserializedData: Record<string, string> = {};
  if (keys && bytesArray.length !== keys?.length){
    throw Error("Number of keys to deserialize must be equal to bytesArray length.")
  }
  const iterable = keys || Object.keys(schema); 
  iterable.forEach((key, index) => {
    const data = bcs.de(schema[key], new Uint8Array(bytesArray[index]));
    deserializedData[key] = data;
  });
  return deserializedData;
}
