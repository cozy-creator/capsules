import { MIST_PER_SUI, SuiTransactionBlockResponse } from "@mysten/sui.js";
import { provider } from "./config";

export function printTxStat(name: string, { digest, effects }: SuiTransactionBlockResponse) {
  console.log(`\n========== ${name} ==========\n`);

  if (effects) {
    const computationCost = Number(effects.gasUsed.computationCost) / Number(MIST_PER_SUI);
    const storageCost = Number(effects.gasUsed.storageCost) / Number(MIST_PER_SUI);

    console.log(`Status : ${effects.status.status}`);
    console.log(`Transaction Digest: ${effects.transactionDigest}`);

    console.log(`Storage cost: ${storageCost} SUI`);
    console.log(`Computation cost: ${computationCost} SUI`);
    console.log(`Total cost: ${storageCost + computationCost} SUI`);

    if (effects.status.error) {
      console.log(`\nError: ${effects.status.error}`);
    }

    console.log();
  }
}

export async function getCreatedIdsFromResponseWithType(response: SuiTransactionBlockResponse, types: string[]) {
  if (!response.effects?.created) throw new Error("Response does not cointain created objects");

  const rawIds = response.effects.created.map((obj) => obj.reference.objectId);
  const objects = await provider.multiGetObjects({ ids: rawIds, options: { showType: true } });

  const typeIds: string[] = [];
  for (let i = 0; i < types.length; i++) {
    const id = objects.find((obj) => obj.data?.type == types[i]);
    if (!id?.data?.objectId) throw new Error(`ID for type ${types[i]} not found}`);

    typeIds.push(id.data.objectId);
  }

  return typeIds;
}
