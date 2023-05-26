import { TransactionBlock } from "@mysten/sui.js";
import { agentSigner, ownerSigner, packageId } from "./config";

interface EditBaybyInput {
  newName: string;
  delegationStoreId: string;
  babyId: string;
}

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
  const agentAddress = await agentSigner.getAddress();

  txb.moveCall({
    arguments: [txb.object(baby), txb.object(store), txb.pure(agentAddress)],
    target: `${packageId}::capsule_baby::delegate_baby`,
    typeArguments: [],
  });

  return await ownerSigner.signAndExecuteTransactionBlock({ transactionBlock: txb });
}

async function editCapsuleBabyName(input: EditBaybyInput) {
  const txb = new TransactionBlock();

  txb.moveCall({
    arguments: [txb.object(input.babyId), txb.object(input.delegationStoreId), txb.pure(input.newName)],
    target: `${packageId}::capsule_baby::edit_baby_name`,
    typeArguments: [],
  });

  txb.setGasBudget(100000000);

  await agentSigner.signAndExecuteTransactionBlock({ transactionBlock: txb });
}
