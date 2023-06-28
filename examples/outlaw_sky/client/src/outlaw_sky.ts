import { RawSigner, TransactionArgument, TransactionBlock } from "@mysten/sui.js"
import { CREATOR, OTHER, Outlaw, USER } from "../outlaw-sky/outlaw-sky/structs"
import { create, rename } from "../outlaw-sky/outlaw-sky/functions"
import { begin as beginTxAuth } from "../ownership/tx-authority/functions"
import { adminSigner, agentSigner, baseGasBudget, fakeAgentSigner } from "./config"
import { claimActions } from "../ownership/organization/functions"
import { bcs, serializeByField } from "@capsulecraft/serializer"
import { grantOrgActionToRole, revokeActionFromOrgRole, setOrgRoleForAgent } from "./organization"
import { createdObjectsMap, sleep } from "./utils"

interface CreateOutlaw {
    fields: string[][]
    data: number[][]
    owner: string
    org?: string
}

interface RenameOutlaw {
    outlawId: string
    newName: string
}

function createOutlaw(txb: TransactionBlock, { org, owner, data, fields }: CreateOutlaw) {
    const [auth] = !!org ? claimActions(txb, org) : beginTxAuth(txb)
    create(txb, { auth, owner, data, fields })
    txb.setGasBudget(baseGasBudget * 10)
}

function renameOutlaw(txb: TransactionBlock, { outlawId, newName }: RenameOutlaw) {
    const auth = beginTxAuth(txb)
    rename(txb, { auth, newName, outlaw: outlawId })
    txb.setGasBudget(baseGasBudget)
}

async function executeTxb(signer: RawSigner, txb: TransactionBlock) {
    const response = await signer.signAndExecuteTransactionBlock({
        transactionBlock: txb,
        options: { showEffects: true },
    })

    console.log({ digest: response.digest })

    return response
}

async function main() {
    const agentAddr = await agentSigner.getAddress()
    const fakeAgentAddr = await fakeAgentSigner.getAddress()

    const schema = { name: "String", power_level: "u64" }
    const rawData = { name: "Kehinde", power_level: 100_000 }

    const USER_ROLE = "user"
    const CREATOR_ROLE = "creator"

    const USER_TY = USER.$typeName
    const CREATOR_TY = CREATOR.$typeName

    const OTHER_ROLE = "other"
    const OTHER_TY = OTHER.$typeName

    const org = <string>process.env.ORGANIZATION_ID
    const fields = Object.keys(schema).map((val: string) => [val, schema[<keyof typeof schema>val]])
    const data = serializeByField(bcs, rawData, schema).map((fields) => Array.from(fields))

    let outlawId: string

    // setup all roles and actions
    {
        const txb = new TransactionBlock()
        grantOrgActionToRole(txb, { action: CREATOR_TY, role: CREATOR_ROLE, org })
        grantOrgActionToRole(txb, { action: USER_TY, role: USER_ROLE, org })
        grantOrgActionToRole(txb, { action: OTHER_TY, role: OTHER_ROLE, org })

        await executeTxb(adminSigner, txb)
        sleep()
    }

    // Delegate the OTHER action to agent as the organization - must succeed
    {
        const txb = new TransactionBlock()
        setOrgRoleForAgent(txb, { agent: agentAddr, org, role: OTHER_ROLE })
        await executeTxb(adminSigner, txb)

        sleep()
    }

    // Create an outlaw with the agent delegation other than CREATOR (OTHER) - must fail
    {
        const txb = new TransactionBlock()
        createOutlaw(txb, { org, fields, data, owner: agentAddr })
        await executeTxb(agentSigner, txb)

        sleep()
    }

    // Delegate the CREATOR action to agent as the organization - must succeed
    {
        const txb = new TransactionBlock()
        setOrgRoleForAgent(txb, { agent: agentAddr, org, role: CREATOR_ROLE })
        await executeTxb(adminSigner, txb)

        sleep()
    }

    // Create an outlaw with the agent delegation - must succeed
    {
        const txb = new TransactionBlock()
        createOutlaw(txb, { org, fields, data, owner: agentAddr })
        const resp = await executeTxb(agentSigner, txb)

        const objects = await createdObjectsMap(resp)
        outlawId = objects.get(Outlaw.$typeName)

        sleep()
    }

    // Create an outlaw with the fake agent (agent without delegation) - must fail
    {
        const txb = new TransactionBlock()
        createOutlaw(txb, { fields, data, owner: fakeAgentAddr })
        await executeTxb(fakeAgentSigner, txb)

        sleep()
    }

    // Revoke the CREATOR action from the role
    {
        const txb = new TransactionBlock()
        revokeActionFromOrgRole(txb, { action: CREATOR_TY, org, role: CREATOR_ROLE })
        await executeTxb(adminSigner, txb)

        sleep()
    }

    // Create an outlaw with the agent delegation - must fail
    {
        const txb = new TransactionBlock()
        createOutlaw(txb, { org, fields, data, owner: agentAddr })
        await executeTxb(agentSigner, txb)

        sleep()
    }

    // Rename outlaw by owner - must succeed
    {
        const txb = new TransactionBlock()
        renameOutlaw(txb, { newName: "Rahman", outlawId })
        await executeTxb(agentSigner, txb)

        sleep()
    }

    // Rename outlaw by non-owner - must fail
    {
        const txb = new TransactionBlock()
        renameOutlaw(txb, { newName: "Yusuf", outlawId })
        await executeTxb(fakeAgentSigner, txb)

        sleep()
    }
}

main()
