# CapsuleCraft - Serializer SDK

## Intro

A small typescript sdk consisting of (de)serializing funtions. The purpose of this tool is to prepare argument data to invoke Move functions on the Sui blockchain.

## Installation

`npm install @capsulecraft/serialization

## Usage

For simple usage check the examples folder

## Caveats

Note that this serializer does not support arbitrary nested objects. For example, this will not work:

```
const nestedSchema = {
    inner: {
        value: 'u64'
    }
} as const;
```

Even though `u64` is a primitive Move value and is itself supported, the nesting structure is not; you would need to register a special struct type in the @Mysten/bcs library to serialize this sort of object. Flatter objects will work just fine though:

```
const notNestedSchema = {
    inner: 'u64'
} as const;
```

### Common Errors

If you get a 'fetch() not found error' from the @Mysten/sui.js library, upgrade your version of node to 17.5 or higher. No more need for polymorphic-fills!

## License

MIT
