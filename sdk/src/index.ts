import { BCS, BcsConfig } from "@mysten/bcs";
import { DevInspectResults } from "@mysten/sui.js";
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

// ===== Instantiate bcs, and define Option enums =====

let bcsConfig: BcsConfig = {
  vectorType: "vector",
  addressLength: 20,
  addressEncoding: "hex",
  types: {
    enums: {
      "Option<u64>": {
        none: null,
        some: "u64",
      },
      "Option<ascii>": {
        none: null,
        some: "ascii",
      },
    },
  },
  withPrimitives: true,
};

let bcs = new BCS(bcsConfig);

// ===== Register ascii and utf8 as custom primitive types =====

bcs.registerType(
  "ascii",
  (writer, data: string) => {
    let bytes = new TextEncoder().encode(data);
    if (bytes.length > data.length) throw Error("Not ASCII string");

    writer.writeVec(Array.from(bytes), (w, el: number) => {
      if (el > 127) throw Error("Not ASCII string");
      return w.write8(el);
    });

    return writer;
  },
  (reader) => {
    let bytes = reader.readBytes(reader.readULEB());
    bytes.forEach((byte) => {
      if (byte > 127) throw Error("Not ASCII string");
    });

    return new TextDecoder("ascii").decode(bytes);
  },
  (value) => typeof value == "string"
);

bcs.registerType(
  "utf8",
  (writer, data: string) => {
    let bytes = new TextEncoder().encode(data);
    writer.writeVec(Array.from(bytes), (w, el) => w.write8(el));
    return writer;
  },
  (reader) => {
    let bytes = reader.readBytes(reader.readULEB());
    return new TextDecoder("utf8").decode(bytes);
  },
  (value) => typeof value == "string"
);

type JSTypes<T extends Record<string, keyof MoveToJSTypes>> = {
  -readonly [K in keyof T]: MoveToJSTypes[T[K]];
};

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
  "Option<ascii>": { none: null } | { some: string };
};

type GenericType = Record<string, Uint8Array | boolean | number | bigint | string | number[] | { none: null } | { some: string }>

const MoveToStruct: Record<string, any> = {
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

/**
 * Generates a Move Struct validator from a provided schema.
 *
 * @param {Record<string, string>} schema - an object that maps keys of data to their data types.
 * @returns {Struct<{ [x: string]: any }, Record<string, any>>} - a Move Struct validator with fields matching the provided schema.
 */
function moveStructValidator(
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

/**
 * Serializes data into an array of arrays of bytes using the provided BCS, schema, and optionally a list of onlyKeys.
 *
 * @param {BCS} bcs - the Byte Conversion Service to be used for serialization.
 * @param {any} data - the data to be serialized.
 * @param {Record<string, string>} schema - an object that maps keys of data to their data types.
 * @param {string[]} [onlyKeys] - an optional list of keys to be serialized.
 * @returns {number[][]} - an array of arrays of bytes representing the serialized data.
 */
function serializeByField<T>(
  bcs: BCS,
  data: GenericType,
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
  console.log(serializedData)
  return serializedData;
}

function serializeBcs(bcs: BCS, dataType: string, data: Record<string,string>): number[] {
  return ser(bcs, data, dataType);
}

function deserializeBcs(
  bcs: BCS,
  dataType: string,
  byteArray: Uint8Array
): Record<string, string> {
  return bcs.de(dataType, byteArray);
}

/**
 * Deserializes an array of arrays of bytes into a Record of key-value pairs using the provided BCS and schema.
 *
 * @param {BCS} bcs - the Byte Conversion Service to be used for deserialization.
 * @param {Uint8Array[]} bytesArray - the array of arrays of bytes to be deserialized.
 * @param {Record<string, string>} schema - an object that maps keys of data to their data types.
 * @param {string[]} [keys] - an optional list of keys to be deserialized.
 * @returns {Record<string, string> | null} - a Record of key-value pairs representing the deserialized data, or null if the number of keys and bytesArray length do not match.
 */
function deserializeByField<T>(
  bcs: BCS,
  bytesArray: Uint8Array[],
  schema: Record<string, string>,
  keys?: string[]
): Record<string, string> | null {
  let deserializedData: Record<string, string> = {};
  if (keys && bytesArray.length !== keys?.length) {
    throw Error(
      "Number of keys to deserialize must be equal to bytesArray length."
    );
  }
  const iterable = keys || Object.keys(schema);
  iterable.forEach((key, index) => {
    const data = bcs.de(schema[key], new Uint8Array(bytesArray[index]));
    deserializedData[key] = data;
  });
  return deserializedData;
}

function parseViewResults(result: DevInspectResults): Uint8Array {
  // TO DO: we can't just remove the 0th byte; that will fail if there are more than 128 items
  // in the response. Instead we need to parse the ULEB128 and remove that
  // @ts-ignore
  const data = result.results.Ok[0][1].returnValues[0][0] as Uint8Array;

  // Delete the first tunnecessary ULEB128 length auto-added by the sui bcs view-function response
  // data.splice(0, 1);
  const dataCrop = data.slice(1, data.length);
  return dataCrop;
}

export {
  serializeByField,
  deserializeByField,
  parseViewResults,
  moveStructValidator,
  JSTypes,
  bcs,
  deserializeBcs,
};
