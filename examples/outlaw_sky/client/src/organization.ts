import { TransactionBlock } from "@mysten/sui.js"
import {
    createFromReceipt,
    grantActionToRole,
    returnAndShare,
    revokeActionFromRole,
    setRoleForAgent,
} from "../ownership/organization/functions"
import { begin as beginTxAuth } from "../ownership/tx-authority/functions"

export interface RoleAction {
    org: string
    role: string
    action: string
}

export interface SetRoleForAgent {
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

export function grantOrgActionToRole(txb: TransactionBlock, { action, org, role }: RoleAction) {
    const [auth] = beginTxAuth(txb)
    grantActionToRole(txb, action, { auth, org, role })
}

export function setOrgRoleForAgent(txb: TransactionBlock, { agent, org, role }: SetRoleForAgent) {
    const [auth] = beginTxAuth(txb)
    setRoleForAgent(txb, { agent, auth, org, role })
}

export function revokeActionFromOrgRole(txb: TransactionBlock, { action, org, role }: RoleAction) {
    const [auth] = beginTxAuth(txb)
    revokeActionFromRole(txb, action, { auth, org, role })
}
