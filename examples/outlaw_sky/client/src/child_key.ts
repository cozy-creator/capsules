import { Ed25519Keypair, RawSigner, TransactionBlock } from "@mysten/sui.js"
import { adminSigner, agentSigner, baseGasBudget, provider } from "./config"
import { createdObjectsMap, executeTxb } from "./utils"
import {
    createPerson_,
    delegateObjectAction_,
    delegateTypeAction_,
    renameWarship_,
    setOrgRoleForAgent_,
    undelegateObjectAction_,
    undelegateTypeAction_,
} from "."
import { Person } from "../ownership/person/structs"
import { ADMIN } from "../ownership/action/structs"
import { create, rename } from "../outlaw-sky/warship/functions"
import { begin as beginTxAuth } from "../ownership/tx-authority/functions"
import { bcs, serializeByField } from "@capsulecraft/serializer"
import { Warship } from "../outlaw-sky/warship/structs"
import { claimActions } from "../ownership/organization/functions"
import { claimDelegation } from "../ownership/person/functions"

export interface CreateWarship {
    fields: string[][]
    data: number[][]
    owner: string
}

export interface RenameWarship {
    warshipId: string
    personId?: string
    newName: string
}

function generateChildKeySigner() {
    const childKey = Ed25519Keypair.generate()
    return new RawSigner(childKey, provider)
}

async function fundChildKey(addr: string) {
    const txb = new TransactionBlock()
    const [coin] = txb.splitCoins(txb.gas, [txb.pure(1000000000)])
    txb.transferObjects([coin], txb.pure(addr))

    await executeTxb(adminSigner, txb)
}

export function createWarship(txb: TransactionBlock, org: string, data: CreateWarship[]) {
    const [auth] = !!org ? claimActions(txb, org) : beginTxAuth(txb)
    for (let i = 0; i < data.length; i++) {
        create(txb, { auth, ...data[i] })
    }

    txb.setGasBudget(baseGasBudget * 10)
}

export function renameWarship(
    txb: TransactionBlock,
    { personId, warshipId, newName }: RenameWarship
) {
    const [auth] = !!personId ? claimDelegation(txb, personId) : beginTxAuth(txb)
    rename(txb, { auth, newName, warship: warshipId })
    txb.setGasBudget(baseGasBudget)
}

async function main() {
    const agentAddr = await agentSigner.getAddress()

    const childKeySigner = generateChildKeySigner()
    const childKeyAddr = await childKeySigner.getAddress()

    const ADMIN_TY = ADMIN.$typeName
    const CREATOR_ROLE = "creator"

    const org = <string>process.env.ORGANIZATION_ID

    const schema = { name: "String", size: "u64", strength: "u64" }

    let personId: string,
        warships: string[] = []

    {
        console.log("Fund child key with some SUI")
        await fundChildKey(childKeyAddr)
    }

    {
        console.log('Delegate the "CREATOR" action to agent as the organization')
        await setOrgRoleForAgent_(adminSigner, { agent: agentAddr, org, role: CREATOR_ROLE })
    }

    {
        console.log("Create person object for the outlaw owner")
        const resp = await createPerson_(agentSigner, agentAddr)
        const objects = await createdObjectsMap(resp)
        personId = objects.get(Person.$typeName)![0]
    }

    {
        const fields = Object.keys(schema).map((val: string) => [
            val,
            schema[<keyof typeof schema>val],
        ])
        const rawData = [
            { name: "WRS 8D9", strength: 3000, size: 150 },
            { name: "WRS 5G2", strength: 5470, size: 145 },
            { name: "WRS 9O1", strength: 7655, size: 132 },
        ]

        const data = rawData.map((data) => ({
            data: serializeByField(bcs, data, schema).map((fields) => Array.from(fields)),
            owner: agentAddr,
            fields,
        }))

        const txb = new TransactionBlock()
        createWarship(txb, org, data)
        const response = await executeTxb(agentSigner, txb)
        const objects = await createdObjectsMap(response)

        warships = objects.get(Warship.$typeName)!
    }

    {
        console.log("Delegate an outlaw with the outlaw owner's person object")
        await delegateObjectAction_(agentSigner, {
            action: ADMIN_TY,
            agent: childKeyAddr,
            objects: [warships[0]],
            personId,
        })
    }

    {
        console.log("Warship rename")
        await renameWarship_(childKeySigner, {
            personId,
            warshipId: warships[0],
            newName: "Some othername",
        })
    }

    {
        console.log("Warship rename")
        await renameWarship_(childKeySigner, {
            personId,
            warshipId: warships[1],
            newName: "Some othername",
        })
    }

    {
        console.log("Delegate an outlaw with the outlaw owner's person object")
        await delegateTypeAction_(agentSigner, {
            action: ADMIN_TY,
            agent: childKeyAddr,
            type: Warship.$typeName,
            personId,
        })
    }

    {
        console.log("Warship rename")
        await renameWarship_(childKeySigner, {
            personId,
            warshipId: warships[1],
            newName: "Some othername",
        })
    }

    {
        console.log("Undelegate an outlaw with the outlaw owner's person object")
        await undelegateTypeAction_(agentSigner, {
            action: ADMIN_TY,
            agent: childKeyAddr,
            type: Warship.$typeName,
            personId,
        })
    }

    {
        console.log("Warship rename")
        await renameWarship_(childKeySigner, {
            personId,
            warshipId: warships[1],
            newName: "Some othername",
        })
    }

    {
        console.log("Undelegate an outlaw with the outlaw owner's person object")
        await undelegateObjectAction_(agentSigner, {
            action: ADMIN_TY,
            agent: childKeyAddr,
            objects: [warships[0]],
            personId,
        })
    }

    {
        console.log("Warship rename")
        await renameWarship_(childKeySigner, {
            personId,
            warshipId: warships[1],
            newName: "Some othername",
        })
    }
}

main()
