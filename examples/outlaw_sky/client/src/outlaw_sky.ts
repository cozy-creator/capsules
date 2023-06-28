import { TransactionBlock } from "@mysten/sui.js"
import { create, rename } from "../outlaw-sky/outlaw-sky/functions"
import { begin as beginTxAuth } from "../ownership/tx-authority/functions"
import { baseGasBudget } from "./config"
import { claimActions } from "../ownership/organization/functions"
import { claimDelegation } from "../ownership/person/functions"

export interface CreateOutlaw {
    fields: string[][]
    data: number[][]
    owner: string
    org?: string
}

export interface RenameOutlaw {
    outlawId: string
    personId?: string
    newName: string
}

export function createOutlaw(txb: TransactionBlock, { org, owner, data, fields }: CreateOutlaw) {
    const [auth] = !!org ? claimActions(txb, org) : beginTxAuth(txb)
    create(txb, { auth, owner, data, fields })
    txb.setGasBudget(baseGasBudget * 10)
}

export function renameOutlaw(txb: TransactionBlock, { personId, outlawId, newName }: RenameOutlaw) {
    const [auth] = !!personId ? claimDelegation(txb, personId) : beginTxAuth(txb)
    rename(txb, { auth, newName, outlaw: outlawId })
    txb.setGasBudget(baseGasBudget)
}
