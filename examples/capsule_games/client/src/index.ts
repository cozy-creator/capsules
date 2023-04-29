import { JSTypes, bcs, getSigner } from '../../../../sdk/typescript/src';
import { RawSigner, TransactionBlock } from '@mysten/sui.js';
import path from 'path';

// This path might vary on other machines--it requires the latest Sui CLI to be installed
const ENV_PATH = path.resolve(__dirname, '../../../../', '.env');

// Devnet addresses
const gamesPackageID = '0xa1c2e500ae952c9955560c27148a256d9d47e59683ed9a3ff780891be31915f6';

// These are the options for the transaction block
const options = {
  showInput: true,
  showEffects: true,
  showEvents: true,
  showObjectChanges: true
};

async function main(signer: RawSigner) {
  let signerAddress = await signer.getAddress();
  console.log('signer: ', signerAddress);

  // ====== Define Pull Info ======
  const pullInfoSchema = {
    uid: 'ID',
    nonce: 'u64',
    premium: 'bool',
    fixed_traits: 'VecMap'
  } as const;

  type PullInfo = JSTypes<typeof pullInfoSchema>;

  // TO DO: we need to fetch the current version of the object here, so we have the correct nonce

  let pullInfo: PullInfo = {
    uid: '0x801577ac903ef662f64c1e0b2300c1d635978875353f8e9f7cfc47e3fe966e4d',
    nonce: 0n,
    premium: true,
    fixed_traits: { hat: 'black', shirt: 'red' }
  };

  bcs.registerStructType('PullInfo', pullInfoSchema);
  let data = bcs.ser('PullInfo', pullInfo).toBytes();

  console.log(data);

  let signature = await signer.signData(data);
  let message = await signer.signMessage({ message: data });
  console.log(message.messageBytes);
  console.log(message.signature);
  console.log(signature);

  // ====== Submit transaction ======

  let tx = new TransactionBlock();
  tx.moveCall({
    target: `${gamesPackageID}::outlaw_sky::check_signature`,
    arguments: [tx.pure(data.toString()), tx.pure(signature), tx.pure(signerAddress)]
    // arguments: [tx.pure(message.messageBytes), tx.pure(message.signature), tx.pure(signerAddress)]
  });
  const response = await signer.devInspectTransactionBlock({ transactionBlock: tx });
  console.log(response);

  // @ts-ignore
  console.log(response.results[0].returnValues);

  // @ts-ignore
  console.log(response.effects.mutated[0]);

  //   let tx = new TransactionBlock();
  //   tx.moveCall({
  //     target: `${displayPackageID}::creator::create`,
  //     arguments: [tx.pure(signerAddress)]
  //   });
  //   const tx2Response = await signer.signAndExecuteTransactionBlock({
  //     transactionBlock: tx,
  //     options
  //   });
}

getSigner(ENV_PATH).then(signer => main(signer));
