import { serializeByField } from "../src/index";

describe("serializeByField", () => {
  it("should return an array of arrays of bytes", () => {
    const data = { name: "John Doe", age: 30 };
    const schema = { name: "string", age: "u8" };
    const result = serializeByField(data, schema);
    console.log(result);
    expect(result).toEqual([[8, 74, 111, 104, 110, 32, 68, 111, 101], [30]]);
  });

  it("should serialize only the specified keys when onlyKeys is provided", () => {
    const data = { name: "John Doe", age: 30, city: "San Francisco" };
    const schema = { name: "string", age: "u8", city: "string" };
    const onlyKeys = ["name", "city"];
    const result = serializeByField(data, schema, onlyKeys);
    console.log(result);
    expect(result).toEqual([
      [8, 74, 111, 104, 110, 32, 68, 111, 101],
      [13, 83, 97, 110, 32, 70, 114, 97, 110, 99, 105, 115, 99, 111],
    ]);
  });

  it('should serialize all keys when onlyKeys is not provided', () => {
    const data = { name: 'John Doe', age: 30, city: 'San Francisco' };
    const schema = { name: 'string', age: 'u8', city: 'string' };
    const result = serializeByField(data, schema);
    console.log(result);
    expect(result).toEqual([[
      8, 74, 111, 104,
    110, 32,  68, 111,
    101
  ],
  [ 30 ],
  [
     13,  83, 97, 110, 32,
     70, 114, 97, 110, 99,
    105, 115, 99, 111
  ]]);
  });

  it('should serialize an address', () => {});

  it('should serialize a bool', () => {
    const data = {flag: true}
    const schema = {flag: "bool"}
    const result = serializeByField(data, schema);
    expect(result).toEqual([[1]]);
  });

  it('should serialize a u8 ', () => {});

  it('should serialize a u16 ', () => {});

  it('should serialize a u32 ', () => {});

  it('should serialize a u64 ', () => {});

  it('should serialize a u128 ', () => {});

  it('should serialize a u256 ', () => {});

  it('should serialize a string ', () => {
    const data = {flag: "george"}
    const schema = {flag: "string"}
    const result = serializeByField(data, schema);
    console.log(result)
    expect(result).toEqual([[6, 103, 101,111, 114, 103,101]]);
  });

  it('should serialize a VecMap', () => {
    const data = {meta: { name: 'John Doe', age: 30, city: 'San Francisco' }};
    const schema = {flag: "VecMap"};
    // const result = serializeByField(data, schema);
    // console.log(result)
    // const output = [1, 4,34,43,34, 6,43,34,123,234]
  });

  it('should serialize a vector<u8> ', () => {});

  it('should serialize a vector<string> ', () => {});


});
