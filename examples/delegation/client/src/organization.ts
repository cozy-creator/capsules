import { SuiParsedData, TransactionBlock } from "@mysten/sui.js";
import {
  beginTxAuth,
  createOrganizationFromPublishReceipt,
  destroyOrganization,
  removeOrganizationPackage,
  returnAndShareOrganization,
} from "./txb";
import { basGasBudget, ownerSigner, publishReceiptId } from "./config";
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
  txb.setGasBudget(basGasBudget);

  const response = await ownerSigner.signAndExecuteTransactionBlock({ transactionBlock: txb });
  console.log(response);
}

// createAndShareOrganization(publishReceiptId);
// createAndDestroyOrganization(publishReceiptId);
