import { Ed25519Keypair, JsonRpcProvider, RawSigner } from '@mysten/sui.js';
import { BCS, BcsConfig } from '@mysten/bcs';

// ===== First we instantiate bcs, and define Option enums =====

let bcsConfig: BcsConfig = {
  vectorType: 'vector',
  addressLength: 20,
  addressEncoding: 'hex',
  types: {
    enums: {
      'Option<u64>': {
        none: null,
        some: 'u64'
      },
      'Option<ascii>': {
        none: null,
        some: 'ascii'
      }
    }
  },
  withPrimitives: true
};

let bcs = new BCS(bcsConfig);

// ===== Next we register ascii and utf8 as custom primitive types =====

bcs.registerType(
  'ascii',
  (writer, data: string) => {
    let bytes = new TextEncoder().encode(data);
    if (bytes.length > data.length) throw Error('Not ASCII string');

    writer.writeVec(Array.from(bytes), (w, el: number) => {
      if (el > 127) throw Error('Not ASCII string');
      return w.write8(el);
    });

    return writer;
  },
  reader => {
    let bytes = reader.readBytes(reader.readULEB());
    bytes.forEach(byte => {
      if (byte > 127) throw Error('Not ASCII string');
    });

    return new TextDecoder('ascii').decode(bytes);
  },
  value => typeof value == 'string'
);

bcs.registerType(
  'utf8',
  (writer, data: string) => {
    let bytes = new TextEncoder().encode(data);
    writer.writeVec(Array.from(bytes), (w, el) => w.write8(el));
    return writer;
  },
  reader => {
    let bytes = reader.readBytes(reader.readULEB());
    return new TextDecoder('utf8').decode(bytes);
  },
  value => typeof value == 'string'
);

export { bcs };
