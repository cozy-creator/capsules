import { RawSigner, TransactionArgument, TransactionBlock } from "@mysten/sui.js"
import {
    createFromReceipt,
    grantActionToRole,
    returnAndShare,
    revokeActionFromRole,
    setRoleForAgent,
} from "../ownership/organization/functions"
import { adminSigner, agentSigner, baseGasBudget, publishReceiptId } from "./config"
import { CREATOR, USER } from "../outlaw-sky/outlaw-sky/structs"
import { begin as beginTxAuth } from "../ownership/tx-authority/functions"

interface ActionRole {
    auth: TransactionArgument
    org: string
    role: string
    action: string
}

interface SetRoleForAgent {
    agent: string
    auth: TransactionArgument
    org: string
    role: string
}

export async function createOrgFromReceipt(signer: RawSigner, receipt: string) {
    const txb = new TransactionBlock()
    const [org] = createFromReceipt(txb, { owner: await signer.getAddress(), receipt })
    returnAndShare(txb, org)
    txb.setGasBudget(baseGasBudget)

    return await signer.signAndExecuteTransactionBlock({
        transactionBlock: txb,
        options: { showEffects: true },
    })
}

export function grantOrgActionToRole(
    txb: TransactionBlock,
    { action, auth, org, role }: ActionRole
) {
    grantActionToRole(txb, action, { auth, org, role })
}

export function setOrgRoleForAgent(
    txb: TransactionBlock,
    { agent, auth, org, role }: SetRoleForAgent
) {
    setRoleForAgent(txb, { agent, auth, org, role })
}

export function revokeActionFromOrgRole(
    txb: TransactionBlock,
    { action, auth, org, role }: ActionRole
) {
    revokeActionFromRole(txb, action, { auth, org, role })
}
