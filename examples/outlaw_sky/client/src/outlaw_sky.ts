import { RawSigner, TransactionArgument, TransactionBlock } from "@mysten/sui.js";
import { CREATOR, USER } from "../outlaw-sky/outlaw-sky/structs";
import { create } from "../outlaw-sky/outlaw-sky/functions";
import { begin as beginTxAuth } from "../ownership/tx-authority/functions";
import { adminSigner, agentSigner, baseGasBudget, ownerSigner } from "./config";
import { assertLogin, claimActions } from "../ownership/organization/functions";
import { bcs, serializeByField } from "@capsulecraft/serializer";

interface CreateOutlaw {
  signer: RawSigner;
  fields: string[][];
  data: number[][];
  owner: string;
  org?: TransactionArgument | string;
}

async function createOutlaw({ org, signer, owner, data, fields }: CreateOutlaw) {
  const txb = new TransactionBlock();

  let auth;
  if (!!org) {
    [auth] = claimActions(txb, org);
  } else {
    [auth] = beginTxAuth(txb);
  }

  create(txb, { auth, owner, data, fields });
  txb.setGasBudget(baseGasBudget * 10);

  const response = await signer.signAndExecuteTransactionBlock({
    transactionBlock: txb,
  });
  console.log(response);
}

async function main() {
  const owner = await agentSigner.getAddress();
  const schema = { name: "String", power_level: "u64" };

  const fields = Object.keys(schema).map((val: string) => [val, schema[<keyof typeof schema>val]]);
  let data = serializeByField(
    bcs,
    {
      org: "0x84ca23305272e45a049291d8162186384d86913ae341738123fb47e28b06f314",
      name: "Another",
      power_level: 50000,
    },
    schema
  ).map((fields) => Array.from(fields));

  await createOutlaw({ signer: agentSigner, fields, data, owner });
}

main();
