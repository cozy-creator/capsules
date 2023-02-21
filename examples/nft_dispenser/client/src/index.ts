import { BCS, toHEX, getSuiMoveConfig } from "@mysten/bcs";
import { getObjectFields } from "@mysten/sui.js";
import { dispenserObjectId, dispenserPackageId, nftData, provider, signer } from "./config";

async function getRandomnessSignature(randomnessObjectId: string) {
  const res = await provider.call("sui_tblsSignRandomnessObject", [randomnessObjectId, "ConsensusCommitted"]);
  return res as {
    signature: string;
  };
}

async function loadData() {
  const data = serializeNFTsData(nftData);
  const res = await signer.executeMoveCall({
    typeArguments: [],
    arguments: [dispenserObjectId, [...data]],
    function: "load",
    module: "nft_dispenser",
    packageObjectId: dispenserPackageId,
    gasBudget: 30000,
  });

  return res;
}

async function dispense() {
  const dispenserObject = await provider.getObject(dispenserObjectId);

  if (dispenserObject.status == "Exists") {
    const { randomness_id: randomnessObjectId } = getObjectFields(dispenserObject) || {};
    const signature = await getRandomnessSignature(randomnessObjectId);

    const res = await signer.executeMoveCall({
      typeArguments: [],
      arguments: [
        dispenserObjectId,
        randomnessObjectId,
        ["0x7762aabd32826fec88a17ecf95d04b83be694aa4"],
        "0x" + toHEX(Buffer.from(signature.signature, "base64")),
      ],
      function: "dispense",
      module: "nft_dispenser",
      packageObjectId: dispenserPackageId,
      gasBudget: 30000,
    });

    return res;
  } else {
    throw new Error("Invalid dispenser object");
  }
}

function serializeNFTsData(rawData: { name: string; description: string; url: string }[]) {
  const bcs = new BCS(getSuiMoveConfig());

  bcs.registerStructType("NftData", {
    name: "vector<u8>",
    description: "vector<u8>",
    url: "vector<u8>",
  });

  const serializedData: string[] = [];

  for (let i = 0; i < rawData.length; i++) {
    const data = rawData[i];

    const ser = bcs.ser("NftData", {
      name: Buffer.from(data.name),
      description: Buffer.from(data.description),
      url: Buffer.from(data.url),
    });

    serializedData.push("0x" + toHEX(ser.toBytes()));
  }

  return serializedData;
}

// loadData().then(console.log).catch(console.log);
// dispense().then(console.log).catch(console.log);
// getRandomnessSignature().then(console.log).catch(console.log);
