import { TransactionBlock } from "@mysten/sui.js"
import { Organization } from "../ownership/organization/structs"
import { adminSigner, publishReceiptId } from "./config"
import { createOrgFromReceipt } from "./organization"
import { createdObjectsMap, executeTxb } from "./utils"

async function main() {
    const txb = new TransactionBlock()
    const owner = await adminSigner.getAddress()

    createOrgFromReceipt(txb, { owner, receipt: publishReceiptId })

    const response = await executeTxb(adminSigner, txb)
    const objects = await createdObjectsMap(response)

    console.log("Creating setup objects...")
    console.log(`New Organization ID: ${objects.get(Organization.$typeName)}`)
}

main()
