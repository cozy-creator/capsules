import { bcs, serializeByField } from "@capsulecraft/serializer"
import { CREATOR, USER, Outlaw } from "../outlaw-sky/outlaw-sky/structs"
import { adminSigner, agentSigner, delegateSigner, fakeAgentSigner } from "./config"
import { RawSigner, TransactionBlock } from "@mysten/sui.js"
import {
    RoleAction,
    SetRoleForAgent,
    grantOrgActionToRole,
    revokeActionFromOrgRole,
    setOrgRoleForAgent,
} from "./organization"
import { createdObjectsMap, executeTxb, sleep } from "./utils"
import { CreateOutlaw, RenameOutlaw, createOutlaw, renameOutlaw } from "./outlaw_sky"
import { ObjectAction, createPerson, delegateObjectAction, undelegateObjectAction } from "./person"
import { Person } from "../ownership/person/structs"

async function createOutlaw_(signer: RawSigner, { org, fields, owner, data }: CreateOutlaw) {
    const txb = new TransactionBlock()
    createOutlaw(txb, { org, fields, data, owner })

    return await executeTxb(signer, txb)
}

async function renameOutlaw_(signer: RawSigner, { personId, newName, outlawId }: RenameOutlaw) {
    const txb = new TransactionBlock()
    renameOutlaw(txb, { personId, newName, outlawId })

    return await executeTxb(signer, txb)
}

async function createPerson_(signer: RawSigner, guardian: string) {
    const txb = new TransactionBlock()
    createPerson(txb, guardian)

    return await executeTxb(signer, txb)
}

async function setupRoles(
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

async function setOrgRoleForAgent_(signer: RawSigner, { agent, role, org }: SetRoleForAgent) {
    const txb = new TransactionBlock()
    setOrgRoleForAgent(txb, { agent, org, role })

    return await executeTxb(signer, txb)
}

async function revokeActionFromOrgRole_(signer: RawSigner, { action, role, org }: RoleAction) {
    const txb = new TransactionBlock()
    revokeActionFromOrgRole(txb, { action, org, role })

    return await executeTxb(adminSigner, txb)
}

async function delegateObjectAction_(
    signer: RawSigner,
    { action, agent, objectId, personId }: ObjectAction
) {
    const txb = new TransactionBlock()
    delegateObjectAction(txb, { action, agent, objectId, personId })

    return await executeTxb(signer, txb)
}

async function undelegateObjectAction_(
    signer: RawSigner,
    { action, agent, objectId, personId }: ObjectAction
) {
    const txb = new TransactionBlock()
    undelegateObjectAction(txb, { action, agent, objectId, personId })

    return await executeTxb(signer, txb)
}

async function main() {
    const agentAddr = await agentSigner.getAddress()
    const fakeAgentAddr = await fakeAgentSigner.getAddress()
    const delegateAddr = await delegateSigner.getAddress()

    const schema = { name: "String", power_level: "u64" }
    const rawData = { name: "Kehinde", power_level: 100_000 }

    const USER_TY = USER.$typeName
    const USER_ROLE = "user"

    const CREATOR_ROLE = "creator"
    const CREATOR_TY = CREATOR.$typeName

    const org = <string>process.env.ORGANIZATION_ID
    const fields = Object.keys(schema).map((val: string) => [val, schema[<keyof typeof schema>val]])
    const data = serializeByField(bcs, rawData, schema).map((fields) => Array.from(fields))

    let outlawId: string, personId: string, otherOutlawId: string

    {
        console.log("Setup the roles and actions for the organizion")
        const data = [
            { action: CREATOR_TY, role: CREATOR_ROLE },
            { action: USER_TY, role: USER_ROLE },
        ]

        await setupRoles(adminSigner, org, data)
        sleep()
    }

    {
        console.log('Grant the "USER" action to agent as the organization')
        await setOrgRoleForAgent_(adminSigner, { agent: agentAddr, org, role: USER_ROLE })
        sleep()
    }

    {
        console.log('Create an outlaw with the agent using the "USER" action')
        await createOutlaw_(agentSigner, { org, fields, data, owner: agentAddr })
        sleep()
    }

    {
        console.log('Delegate the "CREATOR" action to agent as the organization')
        await setOrgRoleForAgent_(adminSigner, { agent: agentAddr, org, role: CREATOR_ROLE })
        sleep()
    }

    {
        console.log('Create an outlaw with the agent using the "CREATOR" action')
        const resp = await createOutlaw_(agentSigner, { org, fields, data, owner: agentAddr })
        const objects = await createdObjectsMap(resp)
        outlawId = objects.get(Outlaw.$typeName)
        sleep()
    }

    {
        console.log('Create another outlaw with the agent using the "CREATOR" action')
        const resp = await createOutlaw_(agentSigner, { org, fields, data, owner: agentAddr })
        const objects = await createdObjectsMap(resp)
        otherOutlawId = objects.get(Outlaw.$typeName)
        sleep()
    }

    {
        console.log("Create an outlaw with the fake agent (agent without delegation)")
        await createOutlaw_(fakeAgentSigner, { fields, data, owner: fakeAgentAddr })
        sleep()
    }

    {
        console.log('Revoke the "CREATOR" action from the role delegated to the agent')
        await revokeActionFromOrgRole_(adminSigner, { action: CREATOR_TY, org, role: CREATOR_ROLE })
        sleep()
    }

    {
        console.log('Create an outlaw with the agent after the "CREATOR" action is revoked')
        await createOutlaw_(agentSigner, { org, fields, data, owner: agentAddr })
        sleep()
    }

    {
        console.log("Rename an outlaw by the outlaw owner")
        await renameOutlaw_(agentSigner, { newName: "Rahman", outlawId })
        sleep()
    }

    {
        console.log("Rename an outlaw by the outlaw fake owner")
        await renameOutlaw_(fakeAgentSigner, { newName: "Yusuf", outlawId })
        sleep()
    }

    {
        console.log("Create person object for the outlaw owner")
        const resp = await createPerson_(agentSigner, agentAddr)
        const objects = await createdObjectsMap(resp)
        personId = objects.get(Person.$typeName)
        sleep()
    }

    {
        console.log("Delegate an outlaw with the outlaw owner's person object")
        await delegateObjectAction_(agentSigner, {
            action: USER_TY,
            agent: delegateAddr,
            objectId: outlawId,
            personId,
        })

        sleep()
    }

    {
        console.log("Rename outlaw by the outlaw delegate recipient")
        await renameOutlaw_(delegateSigner, { personId, outlawId, newName: "Some othername" })
        sleep()
    }

    {
        console.log("Rename undelegated outlaw by the outlaw delegate recipient")
        await renameOutlaw_(delegateSigner, {
            personId,
            outlawId: otherOutlawId,
            newName: "Some othername",
        })

        sleep()
    }

    {
        console.log("Revoke outlaw delegation for agent from outlaw owner's person object")
        await undelegateObjectAction_(agentSigner, {
            action: USER_TY,
            agent: delegateAddr,
            objectId: outlawId,
            personId,
        })

        sleep()
    }

    {
        console.log("Rename outlaw by the outlaw delegate recipient after delegation is revoked")
        await renameOutlaw_(delegateSigner, { personId, outlawId, newName: "Some othername" })
        sleep()
    }
}

main()
