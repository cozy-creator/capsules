import { RawSigner, TransactionBlock } from "@mysten/sui.js"
import {
    createFromReceipt,
    grantActionToRole,
    returnAndShare,
    revokeActionFromRole,
    setRoleForAgent,
} from "../ownership/organization/functions"
import { baseGasBudget } from "./config"
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

export async function createOrgFromReceipt(
    txb: TransactionBlock,
    { receipt, owner }: { receipt: string; owner: string }
) {
    const [org] = createFromReceipt(txb, { owner, receipt })
    returnAndShare(txb, org)
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
