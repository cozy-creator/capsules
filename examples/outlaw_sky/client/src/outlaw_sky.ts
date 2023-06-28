import { RawSigner, TransactionArgument, TransactionBlock } from "@mysten/sui.js"
import { CREATOR, USER } from "../outlaw-sky/outlaw-sky/structs"
import { create } from "../outlaw-sky/outlaw-sky/functions"
import { begin as beginTxAuth } from "../ownership/tx-authority/functions"
import { adminSigner, agentSigner, baseGasBudget, fakeAgentSigner } from "./config"
import { assertLogin, claimActions, grantActionToRole } from "../ownership/organization/functions"
import { bcs, serializeByField } from "@capsulecraft/serializer"
import { grantOrgActionToRole, revokeActionFromOrgRole, setOrgRoleForAgent } from "./organization"
import { sleep } from "./utils"

interface CreateOutlaw {
    signer: RawSigner
    fields: string[][]
    data: number[][]
    owner: string
    org?: TransactionArgument | string
}

async function createOutlaw({ org, signer, owner, data, fields }: CreateOutlaw) {
    const txb = new TransactionBlock()
    const auth = !!org ? claimActions(txb, org) : beginTxAuth(txb)
    create(txb, { auth, owner, data, fields })

    txb.setGasBudget(baseGasBudget * 10)

    const response = await signer.signAndExecuteTransactionBlock({
        transactionBlock: txb,
    })
    console.log(response)
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

    const org = <string>process.env.ORGANIZATION_ID
    const fields = Object.keys(schema).map((val: string) => [val, schema[<keyof typeof schema>val]])
    const data = serializeByField(bcs, rawData, schema).map((fields) => Array.from(fields))

    // Create and grant CREATOR action to role 'creator'
    {
        await grantOrgActionToRole({
            action: CREATOR_TY,
            signer: adminSigner,
            role: CREATOR_ROLE,
            org,
        })
        sleep()
    }

    // Create and grant USER action to role 'user'
    {
        await grantOrgActionToRole({
            action: USER_TY,
            signer: adminSigner,
            role: USER_ROLE,
            org,
        })
        sleep()
    }

    // Delegate the USER action to agent as the organization - must succeed
    {
        await setOrgRoleForAgent({ agent: agentAddr, org, role: USER_ROLE, signer: adminSigner })
        sleep()
    }

    // Create an outlaw with the agent delegation other than CREATOR (USER) - must fail
    {
        await createOutlaw({ org, signer: agentSigner, fields, data, owner: agentAddr })
        sleep()
    }

    // Delegate the CREATOR action to agent as the organization - must succeed
    {
        await setOrgRoleForAgent({
            agent: agentAddr,
            org,
            role: CREATOR_ROLE,
            signer: adminSigner,
        })
        sleep()
    }

    // Create an outlaw with the agent delegation - must succeed
    {
        await createOutlaw({ org, signer: agentSigner, fields, data, owner: agentAddr })
        sleep()
    }

    // Create an outlaw with the fake agent (agent without delegation) - must fail
    {
        await createOutlaw({ org, signer: fakeAgentSigner, fields, data, owner: fakeAgentAddr })
        sleep()
    }

    // Revoke the CREATOR action from the role
    {
        await revokeActionFromOrgRole({
            action: CREATOR_TY,
            signer: adminSigner,
            org,
            role: CREATOR_ROLE,
        })
        sleep()
    }

    // Create an outlaw with the agent delegation - must fail
    {
        await createOutlaw({ org, signer: agentSigner, fields, data, owner: agentAddr })
        sleep()
    }
}

main()
