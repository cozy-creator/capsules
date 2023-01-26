import { BCS } from '@mysten/bcs';
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
  Struct
} from 'superstruct';

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
  'vector<u8>': number[];
  'Option<ascii>': { some: string } | { none: null };
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
  'vector<u8>': array(integer()),
  'Option<ascii>': union([object({ none: any() }), object({ some: string() })])
};

// ====== Helper Functions ======

export function moveStructValidator(
  schema: Record<string, string>
): Struct<{ [x: string]: any }, Record<string, any>> {
  const dynamicStruct: Record<string, any> = {};

  Object.keys(schema).map(key => {
    dynamicStruct[key] = MoveToStruct[schema[key]];
  });

  return object(dynamicStruct);
}

export function serialize<T>(bcs: BCS, structName: string, data: T): number[] {
  return Array.from(bcs.ser(structName, data).toBytes());
}
