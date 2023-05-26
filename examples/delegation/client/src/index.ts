import { TransactionBlock } from "@mysten/sui.js";
import { agentSigner, ownerSigner, packageId } from "./config";

async function crateDelegationStore() {
  const txb = new TransactionBlock();
  txb.moveCall({
    arguments: [],
    target: `${packageId}::capsule_baby::create_delegation_store`,
    typeArguments: [],
  });

  return await ownerSigner.signAndExecuteTransactionBlock({ transactionBlock: txb });
}

async function createCapsuleBaby(name: string) {
  const txb = new TransactionBlock();

  const [baby] = txb.moveCall({
    arguments: [txb.pure(name)],
    target: `${packageId}::capsule_baby::create_baby`,
    typeArguments: [],
  });

  txb.moveCall({
    arguments: [baby],
    target: `${packageId}::capsule_baby::return_and_share`,
    typeArguments: [],
  });

  return await ownerSigner.signAndExecuteTransactionBlock({ transactionBlock: txb });
}

async function delegateCapsuleBaby(baby: string, store: string) {
  const txb = new TransactionBlock();

  txb.moveCall({
    arguments: [
      txb.object(baby),
      txb.object(store),
      txb.pure("0x785ac476958ad86a9210ef55dadd5c5181c1d23813b4dd7d8cfa0a3aa48b7b3c"),
    ],
    target: `${packageId}::capsule_baby::delegate_baby`,
    typeArguments: [],
  });

  return await ownerSigner.signAndExecuteTransactionBlock({ transactionBlock: txb });
}

async function editCapsuleBabyName(newName: string, baby: string, store: string) {
  const txb = new TransactionBlock();

  txb.moveCall({
    arguments: [txb.object(baby), txb.object(store), txb.pure(newName)],
    target: `${packageId}::capsule_baby::edit_baby_name`,
    typeArguments: [],
  });

  txb.setGasBudget(100000000);

  await agentSigner.signAndExecuteTransactionBlock({ transactionBlock: txb });
}
