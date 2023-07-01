import { TransactionBlock } from "@mysten/sui.js"
import { create, rename } from "../outlaw-sky/outlaw-sky/functions"
import { begin as beginTxAuth } from "../ownership/tx-authority/functions"
import { adminSigner, agentSigner, baseGasBudget, delegateSigner, fakeAgentSigner } from "./config"
import { claimActions } from "../ownership/organization/functions"
import { claimDelegation } from "../ownership/person/functions"
import {
    createOutlaw_,
    createPerson_,
    delegateObjectAction_,
    renameOutlaw_,
    revokeActionFromOrgRole_,
    setOrgRoleForAgent_,
    undelegateObjectAction_,
} from "."
import { Person } from "../ownership/person/structs"
import { createdObjectsMap } from "./utils"
import { CREATOR, Outlaw, USER } from "../outlaw-sky/outlaw-sky/structs"
import { bcs, serializeByField } from "@capsulecraft/serializer"

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

async function main() {
    const agentAddr = await agentSigner.getAddress()
    const fakeAgentAddr = await fakeAgentSigner.getAddress()
    const delegateAddr = await delegateSigner.getAddress()

    const schema = { name: "String", power_level: "u64" }
    const rawData = { name: "Kehinde", power_level: 100_000 }

    const USER_ROLE = "user"
    const USER_TY = USER.$typeName

    const CREATOR_ROLE = "creator"
    const CREATOR_TY = CREATOR.$typeName

    const org = <string>process.env.ORGANIZATION_ID
    const fields = Object.keys(schema).map((val: string) => [val, schema[<keyof typeof schema>val]])
    const data = serializeByField(bcs, rawData, schema).map((fields) => Array.from(fields))

    let outlawId: string, personId: string, otherOutlawId: string

    {
        console.log('Grant the "USER" action to agent as the organization')
        await setOrgRoleForAgent_(adminSigner, { agent: agentAddr, org, role: USER_ROLE })
    }

    {
        console.log('Create an outlaw with the agent using the "USER" action')
        await createOutlaw_(agentSigner, { org, fields, data, owner: agentAddr })
    }

    {
        console.log('Delegate the "CREATOR" action to agent as the organization')
        await setOrgRoleForAgent_(adminSigner, { agent: agentAddr, org, role: CREATOR_ROLE })
    }

    {
        console.log('Create an outlaw with the agent using the "CREATOR" action')
        const resp = await createOutlaw_(agentSigner, { org, fields, data, owner: agentAddr })
        const objects = await createdObjectsMap(resp)
        outlawId = objects.get(Outlaw.$typeName)![0]
    }

    {
        console.log('Create another outlaw with the agent using the "CREATOR" action')
        const resp = await createOutlaw_(agentSigner, { org, fields, data, owner: agentAddr })
        const objects = await createdObjectsMap(resp)
        otherOutlawId = objects.get(Outlaw.$typeName)![0]
    }

    {
        console.log("Create an outlaw with the fake agent (agent without delegation)")
        await createOutlaw_(fakeAgentSigner, { fields, data, owner: fakeAgentAddr })
    }

    {
        console.log('Revoke the "CREATOR" action from the role delegated to the agent')
        await revokeActionFromOrgRole_(adminSigner, { action: CREATOR_TY, org, role: CREATOR_ROLE })
    }

    {
        console.log('Create an outlaw with the agent after the "CREATOR" action is revoked')
        await createOutlaw_(agentSigner, { org, fields, data, owner: agentAddr })
    }

    {
        console.log("Rename an outlaw by the outlaw owner")
        await renameOutlaw_(agentSigner, { newName: "Rahman", outlawId })
    }

    {
        console.log("Rename an outlaw by the outlaw fake owner")
        await renameOutlaw_(fakeAgentSigner, { newName: "Yusuf", outlawId })
    }

    {
        console.log("Create person object for the outlaw owner")
        const resp = await createPerson_(agentSigner, agentAddr)
        const objects = await createdObjectsMap(resp)
        personId = objects.get(Person.$typeName)![0]
    }

    {
        console.log("Delegate an outlaw with the outlaw owner's person object")
        await delegateObjectAction_(agentSigner, {
            action: USER_TY,
            agent: delegateAddr,
            objects: [outlawId],
            personId,
        })
    }

    {
        console.log("Rename outlaw by the outlaw delegate recipient")
        await renameOutlaw_(delegateSigner, { personId, outlawId, newName: "Some othername" })
    }

    {
        console.log("Rename undelegated outlaw by the outlaw delegate recipient")
        await renameOutlaw_(delegateSigner, {
            personId,
            outlawId: otherOutlawId,
            newName: "Some othername",
        })
    }

    {
        console.log("Revoke outlaw delegation for agent from outlaw owner's person object")
        await undelegateObjectAction_(agentSigner, {
            action: USER_TY,
            agent: delegateAddr,
            objects: [outlawId],
            personId,
        })
    }

    {
        console.log("Rename outlaw by the outlaw delegate recipient after delegation is revoked")
        await renameOutlaw_(delegateSigner, { personId, outlawId, newName: "Some othername" })
    }
}

// main()
