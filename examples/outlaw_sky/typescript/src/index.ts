import { Ed25519Keypair, JsonRpcProvider, RawSigner } from '@mysten/sui.js';

// private key: hDZ6+qWBigkbi40a+4Rpxd4NY9Y6+ZEiv0XO6OjQfzy9iW+TkgOZx2RKQIORP4bbY1XrG8Egc+Yo2Q74TNRYUw==
// public key: 0xed2c39b73e055240323cf806a7d8fe46ced1cabb
const privateKeyBytes = new Uint8Array([
  132, 54, 122, 250, 165, 129, 138, 9, 27, 139, 141, 26, 251, 132, 105, 197, 222, 13, 99, 214, 58,
  249, 145, 34, 191, 69, 206, 232, 232, 208, 127, 60, 189, 137, 111, 147, 146, 3, 153, 199, 100, 74,
  64, 131, 145, 63, 134, 219, 99, 85, 235, 27, 193, 32, 115, 230, 40, 217, 14, 248, 76, 212, 88, 83
]);

async function defineOutlawSchema() {
  // Generate a new Keypair
  let keypair = Ed25519Keypair.fromSecretKey(privateKeyBytes);
  const provider = new JsonRpcProvider();
  const signer = new RawSigner(keypair, provider);

  //   console.log(keypair.getPublicKey().toSuiAddress());

  const moveCallTxn = await signer.executeMoveCall({
    packageObjectId: '0x4f2801f232f4cd689e7d1791b74e7fad1dfa068c',
    module: 'schema',
    function: 'define',
    typeArguments: [],
    arguments: [
      ['name', 'image', 'power level'],
      ['ascii', 'ascii', 'u64'],
      [false, false, false]
    ],
    gasBudget: 10000
  });

  console.log('moveCallTxn', moveCallTxn);
}

defineOutlawSchema();
