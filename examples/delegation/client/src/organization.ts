import { SuiParsedData, TransactionBlock } from "@mysten/sui.js";
import {
  beginTxAuth,
  createOrganizationFromPublishReceipt,
  destroyOrganization,
  endorseOrganization,
  removeOrganizationPackage,
  returnAndShareOrganization,
  unendorseOrganization,
} from "./txb";
import { agentSigner, baseGasBudget, ownerSigner, publishReceiptId } from "./config";
import { provider } from "./config";

async function getPackageIdFromPublishReceipt(receipt: string) {
  const object = await provider.getObject({
    id: receipt,
    options: {
      showContent: true,
    },
  });

  if (object.data && object.data.content) {
    // @ts-expect-error
    const { fields } = object.data.content as SuiParsedData;
    return <string>fields.package;
  }

  throw new Error("Invalid publish receipt");
}

async function createAndShareOrganization(publishReceiptId: string) {
  const txb = new TransactionBlock();
  const [organization] = createOrganizationFromPublishReceipt(txb, publishReceiptId);
  returnAndShareOrganization(txb, organization);

  txb.setGasBudget(baseGasBudget);

  const response = await ownerSigner.signAndExecuteTransactionBlock({ transactionBlock: txb });
  console.log(response);
}

async function createAndDestroyOrganization(publishReceiptId: string) {
  const txb = new TransactionBlock();
  const ownerAddress = await ownerSigner.getAddress();
  const packageId = await getPackageIdFromPublishReceipt(publishReceiptId);

  const [auth] = beginTxAuth(txb);
  const [organization] = createOrganizationFromPublishReceipt(txb, publishReceiptId);
  const [pkg] = removeOrganizationPackage(txb, { organization, auth, packageId });

  destroyOrganization(txb, { organization, auth });

  txb.transferObjects([pkg], txb.pure(ownerAddress));
  txb.setGasBudget(baseGasBudget);

  const response = await ownerSigner.signAndExecuteTransactionBlock({ transactionBlock: txb });
  console.log(response);
}

async function createAndEndorseOrganization(publishReceiptId: string) {
  const txb = new TransactionBlock();
  const address = await ownerSigner.getAddress();

  const [auth] = beginTxAuth(txb);
  const [organization] = createOrganizationFromPublishReceipt(txb, publishReceiptId);

  endorseOrganization(txb, { organization, auth, address });
  returnAndShareOrganization(txb, organization);

  txb.setGasBudget(baseGasBudget);

  const response = await ownerSigner.signAndExecuteTransactionBlock({ transactionBlock: txb });
  console.log(response);
}

async function addEndorsementToOrganization(organization: string) {
  const txb = new TransactionBlock();
  const address = await agentSigner.getAddress();

  const [auth] = beginTxAuth(txb);

  endorseOrganization(txb, { organization, auth, address });

  txb.setGasBudget(baseGasBudget);

  const response = await agentSigner.signAndExecuteTransactionBlock({ transactionBlock: txb });
  console.log(response);
}

async function removeEndorsementFromOrganization(organization: string) {
  const txb = new TransactionBlock();
  const address = await agentSigner.getAddress();

  const [auth] = beginTxAuth(txb);

  unendorseOrganization(txb, { organization, auth, address });

  txb.setGasBudget(baseGasBudget);

  const response = await agentSigner.signAndExecuteTransactionBlock({ transactionBlock: txb });
  console.log(response);
}

// createAndShareOrganization(publishReceiptId);
// createAndDestroyOrganization(publishReceiptId);
// createAndEndorseOrganization(publishReceiptId);
// addEndorsementToOrganization("0xe14df24e315fbbf0853dadd28a199f591e6ea9420eeb0c90756acfeda500d1af");
// removeEndorsementFromOrganization("0xe14df24e315fbbf0853dadd28a199f591e6ea9420eeb0c90756acfeda500d1af");
