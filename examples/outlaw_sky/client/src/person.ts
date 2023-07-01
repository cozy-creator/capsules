import { TransactionBlock } from "@mysten/sui.js"
import {
    create,
    returnAndShare,
    addActionForObjects,
    removeActionForObjectsFromAgent,
    addActionForType,
    removeActionForTypesFromAgent,
    addGeneralAction,
    removeGeneralActionFromAgent,
} from "../ownership/person/functions"

import { begin as beginTxAuth } from "../ownership/tx-authority/functions"
import { get as getStructTag } from "../sui-utils/struct-tag/functions"

export interface ObjectAction {
    agent: string
    action: string
    personId: string
    objects: string[]
}

export interface TypeAction {
    agent: string
    action: string
    personId: string
    type: string
}

export function createPerson(txb: TransactionBlock, guardian: string) {
    const [person] = create(txb, guardian)
    returnAndShare(txb, person)
}

export function delegateObjectAction(
    txb: TransactionBlock,
    { agent, action, objects, personId }: ObjectAction
) {
    const [auth] = beginTxAuth(txb)
    addActionForObjects(txb, action, { agent, auth, objects, person: personId })
}

export function undelegateObjectAction(
    txb: TransactionBlock,
    { agent, action, objects, personId }: ObjectAction
) {
    const [auth] = beginTxAuth(txb)
    removeActionForObjectsFromAgent(txb, action, { agent, auth, objects, person: personId })
}

export function delegateTypeAction(
    txb: TransactionBlock,
    { agent, action, type, personId }: TypeAction
) {
    const [auth] = beginTxAuth(txb)
    addActionForType(txb, [type, action], { agent, auth, person: personId })
}

export function undelegateTypeAction(
    txb: TransactionBlock,
    { agent, action, type, personId }: TypeAction
) {
    const [auth] = beginTxAuth(txb)
    const structTag = getStructTag(txb, type)
    removeActionForTypesFromAgent(txb, action, {
        auth,
        agent,
        person: personId,
        types: [structTag],
    })
}

export function delegateGeneralAction(
    txb: TransactionBlock,
    { agent, action, personId }: TypeAction
) {
    const [auth] = beginTxAuth(txb)
    addGeneralAction(txb, action, { agent, auth, person: personId })
}

export function undelegateGeneralAction(
    txb: TransactionBlock,
    { agent, action, personId }: TypeAction
) {
    const [auth] = beginTxAuth(txb)
    removeGeneralActionFromAgent(txb, action, { agent, auth, person: personId })
}
