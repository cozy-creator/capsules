
import { Ed25519Keypair, JsonRpcProvider, RawSigner } from '@mysten/sui.js';
import { privateKeyBytes } from './config';

export const provider = new JsonRpcProvider('https://fullnode.testnet.sui.io:443');

export const signer = new RawSigner(Ed25519Keypair.fromSecretKey(privateKeyBytes), provider);
