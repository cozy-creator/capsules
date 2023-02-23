import { Ed25519Keypair } from "@mysten/sui.js";
import { provider } from "./config";
import crypto from "crypto";
import path from "path";
import fs from "fs";

const ENV_PATH = path.resolve(__dirname, "./", ".env");
const PRIVATE_KEY_ENV_VAR = "PRIVATE_KEY";

function generateKeypair() {
  const seed = crypto.getRandomValues(new Uint8Array(32));
  return Ed25519Keypair.fromSeed(seed);
}

async function faucetRequest(address: string) {
  const response = await provider.requestSuiFromFaucet(address);
  return response.transferred_gas_objects;
}

async function loadEnv(): Promise<string> {
  return new Promise((resolve, reject) => {
    fs.readFile(ENV_PATH, { encoding: "utf8" }, (err, data) => {
      if (err) reject(err);
      resolve(data);
    });
  });
}

async function persistEnv(privateKey: string): Promise<void> {
  const data = `${PRIVATE_KEY_ENV_VAR}=${privateKey}\n`;

  return new Promise((resolve, reject) => {
    fs.writeFile(ENV_PATH, data, { encoding: "utf8" }, (err) => {
      if (err) reject(err);
      resolve();
    });
  });
}

function getPrivateKeyFromEnv(env: string) {
  const lines = env.split("\n");

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    if (line.startsWith(PRIVATE_KEY_ENV_VAR)) {
      const [_, privateKey] = line.split("=");
      return privateKey.trim();
    }
  }
}

async function generateAndPersitKeypair() {
  const keypair = generateKeypair();
  const { privateKey } = keypair.export();
  await persistEnv(privateKey);

  return keypair;
}

async function loadKeypair() {
  try {
    const env = await loadEnv();
    const privateKey = getPrivateKeyFromEnv(env);

    if (privateKey) {
      return Ed25519Keypair.fromSecretKey(Uint8Array.from(Buffer.from(privateKey, "base64")));
    }
    return await generateAndPersitKeypair();
  } catch (e: any) {
    if (e.code == "ENOENT") {
      return await generateAndPersitKeypair();
    }

    throw e;
  }
}

async function getSuiCoins(address: string) {
  const coins = await provider.getCoins(address, "0x2::sui::SUI");
  return coins.data;
}

async function main() {
  const keypair = await loadKeypair();
  const address = keypair.getPublicKey().toSuiAddress();
  const coins = await getSuiCoins(address);

  if (coins.length < 1) {
    await faucetRequest(address);
  }
}

main().then(console.log).catch(console.log);
