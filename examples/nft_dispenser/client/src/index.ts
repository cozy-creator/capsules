import { BCS, toHEX, getSuiMoveConfig } from "@mysten/bcs";
import { adminCapId, dispenserObjectId, dispenserPackageId, nftData, signer } from "./config";

async function loadData() {
  const data = serializeNFTsData(nftData);
  const res = await signer.executeMoveCall({
    typeArguments: [],
    arguments: [dispenserObjectId, adminCapId, [...data]],
    function: "load",
    module: "nft_dispenser",
    packageObjectId: dispenserPackageId,
    gasBudget: 30000,
  });

  return res;
}

async function dispense() {
  const res = await signer.executeMoveCall({
    typeArguments: [],
    arguments: [dispenserObjectId, ["0x7762aabd32826fec88a17ecf95d04b83be694aa4"]],
    function: "dispense",
    module: "nft_dispenser",
    packageObjectId: dispenserPackageId,
    gasBudget: 30000,
  });

  return res;
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
dispense().then(console.log).catch(console.log);
