import { Organization } from "../ownership/organization/structs";
import { adminSigner, publishReceiptId } from "./config";
import { createOrgFromReceipt } from "./organization";
import { createdObjectsMap } from "./utils";

async function main() {
  const response = await createOrgFromReceipt(adminSigner, publishReceiptId);
  const objects = await createdObjectsMap(response);

  console.log("Creating Organinzation...");
  console.log(`New Organization ID: ${objects.get(Organization.$typeName)}`);
}

main();
