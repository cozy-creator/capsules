import { BCS } from "@mysten/bcs";
import { DevInspectResults } from "@mysten/sui.js";
import { Struct } from "superstruct";
declare let bcs: BCS;
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
    string: string;
    "vector<address>": Uint8Array[];
    "vector<bool>": boolean[];
    "vector<id>": Uint8Array[];
    "vector<u8>": Uint8Array;
    "vector<u16>": Uint16Array;
    "vector<u32>": Uint32Array;
    "vector<u64>": BigUint64Array;
    "vector<u128>": BigInt[];
    "vector<u256>": BigInt[];
    "vector<string>": string[];
    "vector<vector<u8>>": Uint8Array[];
    "VecMap<string,string>": Record<string, string>;
    "Option<address>": {
        none: null;
    } | {
        some: Uint8Array;
    };
    "Option<bool>": {
        none: null;
    } | {
        some: boolean;
    };
    "Option<id>": {
        none: null;
    } | {
        some: Uint8Array;
    };
    "Option<u8>": {
        none: null;
    } | {
        some: number;
    };
    "Option<u16>": {
        none: null;
    } | {
        some: number;
    };
    "Option<u32>": {
        none: null;
    } | {
        some: number;
    };
    "Option<u64>": {
        none: null;
    } | {
        some: bigint;
    };
    "Option<u128>": {
        none: null;
    } | {
        some: bigint;
    };
    "Option<u256>": {
        none: null;
    } | {
        some: bigint;
    };
    "Option<string>": {
        none: null;
    } | {
        some: string;
    };
    "Option<vector<address>>": {
        none: null;
    } | {
        some: Uint8Array[];
    };
    "Option<vector<bool>>": {
        none: null;
    } | {
        some: boolean[];
    };
    "Option<vector<id>>": {
        none: null;
    } | {
        some: Uint8Array[];
    };
    "Option<vector<u8>>": {
        none: null;
    } | {
        some: Uint8Array;
    };
    "Option<vector<u16>>": {
        none: null;
    } | {
        some: Uint16Array;
    };
    "Option<vector<u32>>": {
        none: null;
    } | {
        some: Uint32Array;
    };
    "Option<vector<u64>>": {
        none: null;
    } | {
        some: BigUint64Array;
    };
    "Option<vector<u128>>": {
        none: null;
    } | {
        some: BigInt[];
    };
    "Option<vector<u256>>": {
        none: null;
    } | {
        some: BigInt[];
    };
    "Option<vector<string>>": {
        none: null;
    } | {
        some: string[];
    };
    "Option<vector<vector<u8>>>": {
        none: null;
    } | {
        some: Uint8Array[];
    };
    "Option<VecMap<string,string>>": {
        none: null;
    } | {
        some: Record<string, string>;
    };
};
type GenericType = Record<string, Uint8Array | boolean | number | bigint | string | number[] | {
    none: null;
} | {
    some: string;
}>;
/**
 * Generates a Move Struct validator from a provided schema.
 *
 * @param {Record<string, string>} schema - an object that maps keys of data to their data types.
 * @returns {Struct<{ [x: string]: any }, Record<string, any>>} - a Move Struct validator with fields matching the provided schema.
 */
declare function moveStructValidator(schema: Record<string, string>): Struct<{
    [x: string]: any;
}, Record<string, any>>;
declare function serializeBcs(bcs: BCS, dataType: string, data: Record<string, string>): number[];
declare function deserializeBcs(bcs: BCS, dataType: string, byteArray: Uint8Array): Record<string, string>;
/**
 * Serializes data into an array of arrays of bytes using the provided BCS, schema, and optionally a list of onlyKeys.
 *
 * @param {BCS} bcs - the Byte Conversion Service to be used for serialization.
 * @param {any} data - the data to be serialized.
 * @param {Record<string, string>} schema - an object that maps keys of data to their data types.
 * @param {string[]} [onlyKeys] - an optional list of keys to be serialized.
 * @returns {number[][]} - an array of arrays of bytes representing the serialized data.
 */
declare function serializeByField<T>(bcs: BCS, data: GenericType, schema: Record<string, string>, onlyKeys?: string[]): number[][];
/**
 * Deserializes an array of arrays of bytes into a Record of key-value pairs using the provided BCS and schema.
 *
 * @param {BCS} bcs - the Byte Conversion Service to be used for deserialization.
 * @param {Uint8Array[]} bytesArray - the array of arrays of bytes to be deserialized.
 * @param {Record<string, string>} schema - an object that maps keys of data to their data types.
 * @param {string[]} [keys] - an optional list of keys to be deserialized.
 * @returns {Record<string, string> | null} - a Record of key-value pairs representing the deserialized data, or null if the number of keys and bytesArray length do not match.
 */
declare function deserializeByField<T>(bcs: BCS, bytesArray: Uint8Array[], schema: Record<string, string>, keys?: string[]): Record<string, string> | null;
declare function parseViewResults(result: DevInspectResults): Uint8Array;
export { JSTypes, bcs, serializeByField, deserializeByField, serializeBcs, deserializeBcs, parseViewResults, moveStructValidator, };
