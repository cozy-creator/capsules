import { Ed25519Keypair, JsonRpcProvider, RawSigner } from '@mysten/sui.js';
import { BCS, BcsConfig } from '@mysten/bcs';

// public key (hex): 0xed2c39b73e055240323cf806a7d8fe46ced1cabb
// private key (base64): hDZ6+qWBigkbi40a+4Rpxd4NY9Y6+ZEiv0XO6OjQfzy9iW+TkgOZx2RKQIORP4bbY1XrG8Egc+Yo2Q74TNRYUw==
const privateKeyBytes = new Uint8Array([
  132, 54, 122, 250, 165, 129, 138, 9, 27, 139, 141, 26, 251, 132, 105, 197, 222, 13, 99, 214, 58,
  249, 145, 34, 191, 69, 206, 232, 232, 208, 127, 60, 189, 137, 111, 147, 146, 3, 153, 199, 100, 74,
  64, 131, 145, 63, 134, 219, 99, 85, 235, 27, 193, 32, 115, 230, 40, 217, 14, 248, 76, 212, 88, 83
]);

// Build a class to connect to Sui RPC servers
const provider = new JsonRpcProvider('https://fullnode.testnet.sui.io:443');

// Import the above keypair
let keypair = Ed25519Keypair.fromSecretKey(privateKeyBytes);
const signer = new RawSigner(keypair, provider);

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

export { bcs, provider, signer };
