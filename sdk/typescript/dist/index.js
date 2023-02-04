"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.moveStructValidator = exports.parseViewResults = exports.deserializeBcs = exports.serializeBcs = exports.deserializeByField = exports.serializeByField = exports.bcs = void 0;
const bcs_1 = require("@mysten/bcs");
const superstruct_1 = require("superstruct");
// ===== Instantiate bcs, and define Option enums =====
let supportedTypes = [
    "address",
    "bool",
    "id",
    "u8",
    "u16",
    "u32",
    "u64",
    "u128",
    "u256",
    "string",
];
let enums = {};
supportedTypes.map((typeName) => {
    enums[`Option<${typeName}>`] = {
        none: null,
        some: typeName,
    };
    enums[`Option<vector<${typeName}>>`] = {
        none: null,
        some: `vector<${typeName}>`,
    };
});
enums["Option<vector<vector<u8>>>"] = {
    none: null,
    some: "vector<vector<u8>>",
};
enums["Option<VecMap<string,string>>"] = {
    none: null,
    some: "VecMap<string,string>",
};
let bcsConfig = {
    vectorType: "vector",
    addressLength: 20,
    addressEncoding: "hex",
    types: { enums },
    withPrimitives: true,
};
let bcs = new bcs_1.BCS(bcsConfig);
exports.bcs = bcs;
// ===== Register ascii and utf8 as custom primitive types =====
bcs.registerType("string", (writer, data) => {
    let bytes = new TextEncoder().encode(data);
    writer.writeVec(Array.from(bytes), (w, el) => w.write8(el));
    return writer;
}, (reader) => {
    let bytes = reader.readBytes(reader.readULEB());
    return new TextDecoder("utf8").decode(bytes);
}, (value) => typeof value == "string");
const MoveToStruct = {
    address: (0, superstruct_1.array)((0, superstruct_1.integer)()),
    bool: (0, superstruct_1.boolean)(),
    id: (0, superstruct_1.array)((0, superstruct_1.integer)()),
    u8: (0, superstruct_1.integer)(),
    u16: (0, superstruct_1.integer)(),
    u32: (0, superstruct_1.integer)(),
    u64: (0, superstruct_1.bigint)(),
    u128: (0, superstruct_1.bigint)(),
    u256: (0, superstruct_1.bigint)(),
    string: (0, superstruct_1.string)(),
};
Object.keys(MoveToStruct).map((field) => {
    MoveToStruct[`vector<${field}>`] = (0, superstruct_1.array)(MoveToStruct[field]);
});
MoveToStruct["vector<vector<u8>>"] = (0, superstruct_1.array)((0, superstruct_1.array)((0, superstruct_1.integer)()));
MoveToStruct["VecMap<string,string>"] = (0, superstruct_1.array)((0, superstruct_1.array)((0, superstruct_1.string)()));
Object.keys(MoveToStruct).map((field) => {
    MoveToStruct[`Option<${field}>`] = (0, superstruct_1.union)([
        (0, superstruct_1.object)({ none: (0, superstruct_1.any)() }),
        (0, superstruct_1.object)({ some: MoveToStruct[field] }),
    ]);
});
/**
 * Generates a Move Struct validator from a provided schema.
 *
 * @param {Record<string, string>} schema - an object that maps keys of data to their data types.
 * @returns {Struct<{ [x: string]: any }, Record<string, any>>} - a Move Struct validator with fields matching the provided schema.
 */
function moveStructValidator(schema) {
    const dynamicStruct = {};
    Object.keys(schema).map((key) => {
        dynamicStruct[key] = MoveToStruct[schema[key]];
    });
    return (0, superstruct_1.object)(dynamicStruct);
}
exports.moveStructValidator = moveStructValidator;
function ser(bcs, value, key) {
    return Array.from(bcs.ser(key, value).toBytes());
}
function serializeBcs(bcs, dataType, data) {
    return ser(bcs, data, dataType);
}
exports.serializeBcs = serializeBcs;
function deserializeBcs(bcs, dataType, byteArray) {
    return bcs.de(dataType, byteArray);
}
exports.deserializeBcs = deserializeBcs;
/**
 * Serializes data into an array of arrays of bytes using the provided BCS, schema, and optionally a list of onlyKeys.
 *
 * @param {BCS} bcs - the Byte Conversion Service to be used for serialization.
 * @param {any} data - the data to be serialized.
 * @param {Record<string, string>} schema - an object that maps keys of data to their data types.
 * @param {string[]} [onlyKeys] - an optional list of keys to be serialized.
 * @returns {number[][]} - an array of arrays of bytes representing the serialized data.
 */
function serializeByField(bcs, data, schema, onlyKeys) {
    const serializedData = [];
    if (!onlyKeys) {
        for (const [key, keyType] of Object.entries(schema)) {
            const bytesArray = ser(bcs, data[key], keyType);
            serializedData.push(bytesArray);
        }
    }
    else {
        onlyKeys.forEach((key) => {
            const bytesArray = ser(bcs, data[key], schema[key]);
            serializedData.push(bytesArray);
        });
    }
    console.log(serializedData);
    return serializedData;
}
exports.serializeByField = serializeByField;
/**
 * Deserializes an array of arrays of bytes into a Record of key-value pairs using the provided BCS and schema.
 *
 * @param {BCS} bcs - the Byte Conversion Service to be used for deserialization.
 * @param {Uint8Array[]} bytesArray - the array of arrays of bytes to be deserialized.
 * @param {Record<string, string>} schema - an object that maps keys of data to their data types.
 * @param {string[]} [keys] - an optional list of keys to be deserialized.
 * @returns {Record<string, string> | null} - a Record of key-value pairs representing the deserialized data, or null if the number of keys and bytesArray length do not match.
 */
function deserializeByField(bcs, bytesArray, schema, keys) {
    let deserializedData = {};
    if (keys && bytesArray.length !== (keys === null || keys === void 0 ? void 0 : keys.length)) {
        throw Error("Number of keys to deserialize must be equal to bytesArray length.");
    }
    const iterable = keys || Object.keys(schema);
    iterable.forEach((key, index) => {
        const data = bcs.de(schema[key], new Uint8Array(bytesArray[index]));
        deserializedData[key] = data;
    });
    return deserializedData;
}
exports.deserializeByField = deserializeByField;
function parseViewResults(result) {
    // TO DO: we can't just remove the 0th byte; that will fail if there are more than 128 items
    // in the response. Instead we need to parse the ULEB128 and remove that
    // @ts-ignore
    const data = result.results.Ok[0][1].returnValues[0][0];
    // Delete the first tunnecessary ULEB128 length auto-added by the sui bcs view-function response
    // data.splice(0, 1);
    const dataCrop = data.slice(1, data.length);
    return dataCrop;
}
exports.parseViewResults = parseViewResults;
//# sourceMappingURL=index.js.map