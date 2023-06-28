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
    org: string
    role: string
    action: string
}

interface SetRoleForAgent {
    agent: string

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

export function grantOrgActionToRole(txb: TransactionBlock, { action, org, role }: ActionRole) {
    const [auth] = beginTxAuth(txb)
    grantActionToRole(txb, action, { auth, org, role })
}

export function setOrgRoleForAgent(txb: TransactionBlock, { agent, org, role }: SetRoleForAgent) {
    const [auth] = beginTxAuth(txb)
    setRoleForAgent(txb, { agent, auth, org, role })
}

export function revokeActionFromOrgRole(txb: TransactionBlock, { action, org, role }: ActionRole) {
    const [auth] = beginTxAuth(txb)
    revokeActionFromRole(txb, action, { auth, org, role })
}
