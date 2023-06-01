import {
  Connection,
  JsonRpcProvider,
  SignerWithProvider,
  SuiObjectDataWithContent,
  bcs,
} from "@mysten/sui.js";
import { TransactionBlock } from "ethos-connect-vue";
import { getCoinMetataData } from "./utils";

interface CreateDispenserArgs {
  owner: string;
  endDate: number;
  startDate: number;
  price: bigint;
  totalItems: number;
  schema: string;
  isRandom: boolean;
  coinType?: string;
}

export interface DispenserValueType {
  id: string;
  price: bigint;
  balance: bigint;
  endTime: number;
  isRandom: boolean;
  itemSize: number;
  totalItems: number;
  itemsLoaded: number;
  startTime: number;
  coinType: string;
  coinMetadata?: { symbol: string; decimals: number };
  schema: string[];
}

interface SuiObjectContent {
  type: string;
  fields: Record<string, any>;
  hasPublicTransfer: boolean;
  dataType: "moveObject";
}

export interface NFT {
  id: string;
  url: string;
  name: string;
  description: string;
}

const clockObjectId = "0x6";
const dispenserPackageId =
  "0xd1cf8ebdbe62c6f3f5ddd122b00ccb457caa33fce337cefcd5551c2f08c8643f";
const ownerPackageId =
  "0xd6de6cbfd883ce4977ab6d1fdac39bb38a7293e948b735e211516cc52ec8c87b";
const nftPackageId =
  "0x7ac1f4f6b5444632e7856dba0c50a010e0c8f22807b1e0bdaa1ce23eeac1f985";

const notCoinType = `${dispenserPackageId}::dispenser::NOT_COIN`;
const dispenserType = `${dispenserPackageId}::dispenser::Dispenser`;

interface ExecuteOptions {
  signer: SignerWithProvider;
}

export async function executeCreateDispenser(
  {
    owner,
    endDate,
    startDate,
    totalItems,
    isRandom,
    schema,
    price,
    coinType,
  }: CreateDispenserArgs,
  { signer }: ExecuteOptions
) {
  const txb = new TransactionBlock();

  const refinedSchema = (<string[]>JSON.parse(schema)).map((entry) =>
    Array.from(new TextEncoder().encode(entry))
  );

  let createArg;
  if (!coinType) {
    createArg = [
      txb.pure(owner),
      txb.pure(endDate),
      txb.pure(startDate),
      txb.pure(totalItems),
      txb.pure(isRandom),
      txb.pure(refinedSchema),
      txb.pure(clockObjectId),
    ];
  } else {
    createArg = [
      txb.pure(owner),
      txb.pure(price),
      txb.pure(endDate),
      txb.pure(startDate),
      txb.pure(totalItems),
      txb.pure(isRandom),
      txb.pure(refinedSchema),
      txb.pure(clockObjectId),
    ];
  }

  console.log(createArg);
  const [dispenser] = txb.moveCall({
    arguments: createArg,
    typeArguments: coinType ? [coinType] : [],
    target: `${dispenserPackageId}::dispenser::${
      !coinType ? "create_" : "create"
    }`,
  });

  txb.moveCall({
    arguments: [dispenser],
    typeArguments: [coinType || notCoinType],
    target: `${dispenserPackageId}::dispenser::return_and_share`,
  });

  const response = await signer.signAndExecuteTransactionBlock({
    transactionBlock: txb,
    options: { showEffects: true },
  });

  if (!response.effects) throw new Error("");
  const provider = new JsonRpcProvider(
    new Connection({ fullnode: "http://127.0.0.1:9000" })
  );

  const ids = response.effects.created!.map((obj) => obj.reference.objectId);
  const objects = await provider.multiGetObjects({
    ids,
    options: { showType: true },
  });

  let dispenserId;
  for (let i = 0; i < objects.length; i++) {
    const object = objects[i];

    if (object.data?.type == `${dispenserType}<${coinType || notCoinType}>`) {
      dispenserId = object.data.objectId;
    }
  }

  if (!dispenserId)
    throw new Error("Dispenser not found in transaction response");
  return dispenserId;
}

export async function executeLoadDispenserItems(
  {
    dispenserId,
    items,
    coinType,
  }: {
    coinType: string;
    dispenserId: string;
    items: { url: string; name: string }[];
  },
  { signer }: ExecuteOptions
) {
  const txb = new TransactionBlock();
  bcs.registerStructType("NFT", {
    name: "string",
    url: "string",
  });

  const refinedItems = items.map((entry) =>
    Array.from(bcs.ser("NFT", entry).toBytes())
  );

  const [auth] = txb.moveCall({
    arguments: [],
    typeArguments: [],
    target: `${ownerPackageId}::tx_authority::begin`,
  });

  txb.moveCall({
    arguments: [txb.object(dispenserId), txb.pure(refinedItems), auth],
    typeArguments: [coinType],
    target: `${dispenserPackageId}::dispenser::load_items`,
  });

  const response = await signer.signAndExecuteTransactionBlock({
    transactionBlock: txb,
    options: { showEffects: true },
  });

  console.log(response);
}

export async function dispenseItem(
  {
    dispenserId,
    coinType,
  }: {
    coinType?: string;
    dispenserId: string;
  },
  { signer }: ExecuteOptions
) {
  const txb = new TransactionBlock();

  const [idx, itemData] = txb.moveCall({
    typeArguments: coinType ? [coinType] : [],
    target: `${dispenserPackageId}::dispenser::${
      coinType ? "dispense_item" : "dispense_free_item"
    }`,
    arguments: [txb.object(dispenserId), txb.pure(clockObjectId)],
  });

  txb.moveCall({
    typeArguments: [],
    target: `${nftPackageId}::nft::mint`,
    arguments: [idx, itemData],
  });

  const response = await signer.signAndExecuteTransactionBlock({
    transactionBlock: txb,
    options: { showEffects: true },
  });

  if (!response.effects) throw new Error("");
  const provider = new JsonRpcProvider(
    new Connection({ fullnode: "http://127.0.0.1:9000" })
  );

  const ids = response.effects.created!.map((obj) => obj.reference.objectId);
  const objects = await provider.multiGetObjects({
    ids,
    options: {
      showContent: true,
      showType: true,
    },
  });

  let nft: NFT | undefined;
  for (let i = 0; i < objects.length; i++) {
    const object = objects[i];

    if (object.data?.type == `${nftPackageId}::nft::NFT`) {
      if (!object.data?.content)
        throw new Error("Unable to fetch dispenser content");

      const { fields } = <SuiObjectContent>(
        (<SuiObjectDataWithContent>object.data).content
      );

      nft = {
        id: fields.id.id,
        name: fields.name,
        url: fields.url,
        description: fields.description,
      };
    }
  }

  if (!nft) throw new Error("Cannot find newly minted NFT");
  return nft;
}

export async function getDispenser(id: string): Promise<DispenserValueType> {
  const provider = new JsonRpcProvider(
    new Connection({ fullnode: "http://127.0.0.1:9000" })
  );

  const object = await provider.getObject({
    id,
    options: {
      showType: true,
      showContent: true,
    },
  });

  if (object.error) throw object.error;
  if (!object.data?.content)
    throw new Error("Unable to fetch dispenser content");

  const { fields, type } = <SuiObjectContent>(
    (<SuiObjectDataWithContent>object.data).content
  );

  const regex = /(\w+)::dispenser::Dispenser<([^>]+)>/;
  const matches = type.match(regex);
  if (!matches) throw new Error("Invalid dispenser type");

  const coinMetadata = await getCoinMetataData(matches[2]);

  return {
    id: fields.id.id,
    isRandom: fields.is_random,
    price: BigInt(fields.price),
    balance: BigInt(fields.balance),
    endTime: Number(fields.end_time),
    startTime: Number(fields.start_time),
    totalItems: Number(fields.total_items),
    itemsLoaded: parseInt(fields.items_loaded),
    itemSize: parseInt(fields.items.fields.size),
    schema: fields.schema.fields.fields.map((entry: number[]) =>
      new TextDecoder().decode(Uint8Array.from(entry))
    ),
    coinType: matches[2],
    coinMetadata: coinMetadata
      ? {
          symbol: coinMetadata.symbol,
          decimals: coinMetadata.decimals,
        }
      : undefined,
  };
}
