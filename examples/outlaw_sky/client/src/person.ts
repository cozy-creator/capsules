import { TransactionBlock } from "@mysten/sui.js"
import { create, returnAndShare, addActionForObjects } from "../ownership/person/functions"

import { begin as beginTxAuth } from "../ownership/tx-authority/functions"

interface ObjectAction {
    agent: string
    action: string
    personId: string
    objectId: string
}

export function createPerson(txb: TransactionBlock, guardian: string) {
    const [person] = create(txb, guardian)
    returnAndShare(txb, person)
}

export function delegateObjectAction(
    txb: TransactionBlock,
    { agent, action, objectId, personId }: ObjectAction
) {
    const [auth] = beginTxAuth(txb)
    addActionForObjects(txb, action, { agent, auth, objects: [objectId], person: personId })
}
