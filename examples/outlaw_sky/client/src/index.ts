import { RawSigner, TransactionBlock } from "@mysten/sui.js"
import {
    RoleAction,
    SetRoleForAgent,
    grantOrgActionToRole,
    revokeActionFromOrgRole,
    setOrgRoleForAgent,
} from "./organization"
import { executeTxb } from "./utils"
import { CreateOutlaw, RenameOutlaw, createOutlaw, renameOutlaw } from "./outlaw_sky"
import {
    ObjectAction,
    TypeAction,
    createPerson,
    delegateObjectAction,
    delegateTypeAction,
    undelegateObjectAction,
    undelegateTypeAction,
} from "./person"
import { RenameWarship, renameWarship } from "./child_key"

export async function createOutlaw_(signer: RawSigner, { org, fields, owner, data }: CreateOutlaw) {
    const txb = new TransactionBlock()
    createOutlaw(txb, { org, fields, data, owner })
    return await executeTxb(signer, txb)
}

export async function renameOutlaw_(
    signer: RawSigner,
    { personId, newName, outlawId }: RenameOutlaw
) {
    const txb = new TransactionBlock()
    renameOutlaw(txb, { personId, newName, outlawId })
    return await executeTxb(signer, txb)
}

export async function createPerson_(signer: RawSigner, guardian: string) {
    const txb = new TransactionBlock()
    createPerson(txb, guardian)
    return await executeTxb(signer, txb)
}

export async function setupRoles(
    signer: RawSigner,
    org: string,
    data: { role: string; action: string }[]
) {
    const txb = new TransactionBlock()
    for (let i = 0; i < data.length; i++) {
        const d = data[i]
        grantOrgActionToRole(txb, { action: d.action, role: d.role, org })
    }
    return await executeTxb(signer, txb)
}

export async function setOrgRoleForAgent_(
    signer: RawSigner,
    { agent, role, org }: SetRoleForAgent
) {
    const txb = new TransactionBlock()
    setOrgRoleForAgent(txb, { agent, org, role })
    return await executeTxb(signer, txb)
}

export async function revokeActionFromOrgRole_(
    signer: RawSigner,
    { action, role, org }: RoleAction
) {
    const txb = new TransactionBlock()
    revokeActionFromOrgRole(txb, { action, org, role })
    return await executeTxb(signer, txb)
}

export async function delegateObjectAction_(
    signer: RawSigner,
    { action, agent, objects, personId }: ObjectAction
) {
    const txb = new TransactionBlock()
    delegateObjectAction(txb, { action, agent, objects, personId })
    return await executeTxb(signer, txb)
}

export async function undelegateObjectAction_(
    signer: RawSigner,
    { action, agent, objects, personId }: ObjectAction
) {
    const txb = new TransactionBlock()
    undelegateObjectAction(txb, { action, agent, objects, personId })
    return await executeTxb(signer, txb)
}

export async function delegateTypeAction_(
    signer: RawSigner,
    { action, agent, type, personId }: TypeAction
) {
    const txb = new TransactionBlock()
    delegateTypeAction(txb, { type, action, agent, personId })
    return await executeTxb(signer, txb)
}

export async function undelegateTypeAction_(
    signer: RawSigner,
    { action, agent, type, personId }: TypeAction
) {
    const txb = new TransactionBlock()
    undelegateTypeAction(txb, { type, action, agent, personId })
    return await executeTxb(signer, txb)
}

export async function renameWarship_(
    signer: RawSigner,
    { personId, newName, warshipId }: RenameWarship
) {
    const txb = new TransactionBlock()
    renameWarship(txb, { personId, newName, warshipId })
    return await executeTxb(signer, txb)
}
