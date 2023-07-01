import { RawSigner, SuiTransactionBlockResponse, TransactionBlock } from "@mysten/sui.js"
import { provider } from "./config"

export async function createdObjectsMap(txb: SuiTransactionBlockResponse) {
    if (!txb.effects?.created) throw new Error("Cannot find created objects")

    const objects: Map<string, string[]> = new Map()
    const ids = txb.effects.created.map((obj) => obj.reference.objectId)
    const multiObjects = await provider.multiGetObjects({
        ids,
        options: { showType: true },
    })

    for (let i = 0; i < multiObjects.length; i++) {
        const object = multiObjects[i]

        if (object.data) {
            const { type, objectId } = object.data
            if (!type) throw new Error("")

            if (objects.has(type)) {
                objects.set(type, [...objects.get(type)!, objectId])
            } else {
                objects.set(type, [objectId])
            }
        }
    }

    return objects
}

export function sleep(ms = 3000) {
    return new Promise((r) => setTimeout(r, ms))
}

export async function executeTxb(signer: RawSigner, txb: TransactionBlock) {
    const response = await signer.signAndExecuteTransactionBlock({
        transactionBlock: txb,
        options: { showEffects: true },
    })

    console.log(
        {
            digest: response.digest,
            status: response.effects?.status.status,
            error: response.effects?.status.error || "No Error",
        },
        "\n"
    )

    sleep(5)
    return response
}
