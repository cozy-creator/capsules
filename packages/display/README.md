This is an alternative to the Capsules Metadata program; it inherits most of its code from that module.

This is a proposal for how arbitrary Sui objects can be displayed.

### Display Objects

`Display<T>` is an on-chain object that contains a VecMap, mapping keys (as strings) to `vector<String>`. The strings are called 'resolvers'. And they look like this:

[ type, resolver1, resolver2, ...]

A display can have as many resolvers as it likes. They will be tried in order by the Sui Fullnode until a value is returned that matches the specified type, otherwise the Sui Fullnode will return `undefined`.

The Sui Fullnode uses these resolvers to return arbitrary JSON, something like this:

```
{
    name: 'Ceramic Wood',
    thumbnail: 'https://hostingservice.com/0x123.png',
    quantity: 15
}
```

```
{
    name: 'Outlaw',
    attributes: {
        body: 'male',
        mouth: 'Cigar',
        weapon: 'Scythe'
    }
}
```

The keys and the value-types returned in the JSON are specified by the resolver strings contained with the Display object.

For convenience, resolvers can be left undefined, which means that the Fullnode resolver returns object[key] if it has the correct type; for example, if the key is `name` with type `string`, then we it will just return `object.name`, assuming that property is a string in the original Move struct.
