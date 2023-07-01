import { TransactionBlock } from "@mysten/sui.js"
import { Organization } from "../ownership/organization/structs"
import { adminSigner, publishReceiptId } from "./config"
import { createOrgFromReceipt } from "./organization"
import { createdObjectsMap, executeTxb } from "./utils"
import { setupRoles } from "."
import { CREATOR, USER } from "../outlaw-sky/outlaw-sky/structs"

async function main() {
    const owner = await adminSigner.getAddress()

    const USER_ROLE = "user"
    const USER_TY = USER.$typeName

    const CREATOR_ROLE = "creator"
    const CREATOR_TY = CREATOR.$typeName

    let orgId: string

    {
        console.log("Creating organization from publish receipt")
        const txb = new TransactionBlock()
        createOrgFromReceipt(txb, { owner, receipt: publishReceiptId })

        const response = await executeTxb(adminSigner, txb)
        const objects = await createdObjectsMap(response)
        orgId = objects.get(Organization.$typeName)![0]
    }

    {
        console.log("Setup the roles and actions for the organizion")
        const data = [
            { action: CREATOR_TY, role: CREATOR_ROLE },
            { action: USER_TY, role: USER_ROLE },
        ]

        await setupRoles(adminSigner, orgId, data)
    }

    console.log(`New Organization ID: ${orgId}`)
}

main()
