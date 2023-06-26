import { RawSigner, TransactionArgument, TransactionBlock } from "@mysten/sui.js";
import {
  addActionForObjects,
  addActionForType,
  addGeneralAction,
  claimDelegation,
  create as createPerson,
  destroy as destroyPerson,
  removeActionForObjectsFromAgent,
  removeActionForTypeFromAgent,
  removeGeneralActionFromAgent,
  returnAndShare as returnAndSharePerson,
} from "../ownership/person/functions";
import { begin as beginTxAuth } from "../ownership/tx-authority/functions";
import { createBaby, editBabyName, returnAndShare as returnAndShareBaby } from "../capsule-baby/capsule-baby/functions";
import { CAPSULE_BABY, EDITOR } from "../capsule-baby/capsule-baby/structs";

interface CreatePerson {
  signer: RawSigner;
  guardian: string;
}

interface EditBabyWithAction {
  owner: RawSigner;
  agent: RawSigner;
}

type CallArg = string | TransactionArgument;

async function createAndSharePerson({ signer, guardian }: CreatePerson) {
  const txb = new TransactionBlock();
  const [person] = createPerson(txb, guardian);
  returnAndSharePerson(txb, person);

  const _tx = await signer.signAndExecuteTransactionBlock({ transactionBlock: txb });
}

async function createAndDestroyPerson({ signer, guardian }: CreatePerson) {
  const txb = new TransactionBlock();
  const [person] = createPerson(txb, guardian);
  const [auth] = beginTxAuth(txb);
  destroyPerson(txb, { person, auth });

  const _tx = await signer.signAndExecuteTransactionBlock({ transactionBlock: txb });
}

async function editBabyWithGeneralAction({ owner, agent }: EditBabyWithAction) {
  const ownerAddress = await owner.getAddress();
  const agentAddress = await agent.getAddress();

  let personId: string = "",
    babyId: string = "";

  {
    const txb = new TransactionBlock();
    const [person, baby] = createPersonAndBaby(txb, ownerAddress, "Initial Baby name");
    const [auth] = beginTxAuth(txb);

    addGeneralAction(txb, EDITOR.$typeName, { agent: agentAddress, auth, person });
    returnAndSharePersonAndBaby(txb, person, baby);

    const _tx = await owner.signAndExecuteTransactionBlock({ transactionBlock: txb, options: { showEffects: true } });
  }

  claimDelegationAndEditBaby(agent, personId, babyId);
}

async function editBabyWithTypeAction({ owner, agent }: EditBabyWithAction) {
  const ownerAddress = await owner.getAddress();
  const agentAddress = await agent.getAddress();

  let personId: string = "",
    babyId: string = "";

  {
    const txb = new TransactionBlock();
    const [person, baby] = createPersonAndBaby(txb, ownerAddress, "Initial Baby name");
    const [auth] = beginTxAuth(txb);

    addActionForType(txb, [CAPSULE_BABY.$typeName, EDITOR.$typeName], { agent: agentAddress, auth, person });
    returnAndSharePersonAndBaby(txb, person, baby);

    const _tx = await owner.signAndExecuteTransactionBlock({ transactionBlock: txb, options: { showEffects: true } });
  }

  claimDelegationAndEditBaby(agent, personId, babyId);
}

async function editBabyWithObjectAction({ owner, agent }: EditBabyWithAction) {
  const ownerAddress = await owner.getAddress();
  const agentAddress = await agent.getAddress();

  let personId: string = "",
    babyId: string = "";

  {
    const txb = new TransactionBlock();
    const [person, baby] = createPersonAndBaby(txb, ownerAddress, "Initial Baby name");
    returnAndSharePersonAndBaby(txb, person, baby);

    const _tx = await owner.signAndExecuteTransactionBlock({ transactionBlock: txb, options: { showEffects: true } });
  }

  {
    const txb = new TransactionBlock();
    const [auth] = beginTxAuth(txb);
    addActionForObjects(txb, EDITOR.$typeName, { agent: agentAddress, auth, person: personId, objects: [babyId] });

    const _tx = await owner.signAndExecuteTransactionBlock({ transactionBlock: txb, options: { showEffects: true } });
  }

  claimDelegationAndEditBaby(agent, personId, babyId);
}

async function editBabyWithEmptyAction({ owner, agent }: EditBabyWithAction) {
  const ownerAddress = await owner.getAddress();

  let personId: string = "",
    babyId: string = "";

  {
    const txb = new TransactionBlock();
    const [person, baby] = createPersonAndBaby(txb, ownerAddress, "Initial Baby name");
    returnAndSharePersonAndBaby(txb, person, baby);

    const _tx = await owner.signAndExecuteTransactionBlock({ transactionBlock: txb, options: { showEffects: true } });
  }

  claimDelegationAndEditBaby(agent, personId, babyId);
}

async function editBabyWithRemovedGeneralAction({ owner, agent }: EditBabyWithAction) {
  const ownerAddress = await owner.getAddress();
  const agentAddress = await agent.getAddress();

  let personId: string = "",
    babyId: string = "";

  {
    const txb = new TransactionBlock();
    const [person, baby] = createPersonAndBaby(txb, ownerAddress, "Initial Baby name");
    const [auth] = beginTxAuth(txb);

    addGeneralAction(txb, EDITOR.$typeName, { agent: agentAddress, auth, person });
    returnAndSharePersonAndBaby(txb, person, baby);

    const _tx = await owner.signAndExecuteTransactionBlock({ transactionBlock: txb, options: { showEffects: true } });
  }

  {
    const txb = new TransactionBlock();
    const [auth] = beginTxAuth(txb);

    removeGeneralActionFromAgent(txb, EDITOR.$typeName, { agent: agentAddress, auth, person: personId });
    const _tx = await owner.signAndExecuteTransactionBlock({ transactionBlock: txb, options: { showEffects: true } });
  }

  claimDelegationAndEditBaby(agent, personId, babyId);
}

async function editBabyWithRemovedTypeAction({ owner, agent }: EditBabyWithAction) {
  const ownerAddress = await owner.getAddress();
  const agentAddress = await agent.getAddress();

  let personId: string = "",
    babyId: string = "";

  {
    const txb = new TransactionBlock();

    const [person, baby] = createPersonAndBaby(txb, ownerAddress, "Initial Baby name");
    const [auth] = beginTxAuth(txb);

    addActionForType(txb, [CAPSULE_BABY.$typeName, EDITOR.$typeName], { agent: agentAddress, auth, person });
    returnAndSharePersonAndBaby(txb, person, baby);

    const _tx = await owner.signAndExecuteTransactionBlock({ transactionBlock: txb, options: { showEffects: true } });
  }

  {
    const txb = new TransactionBlock();
    const [auth] = beginTxAuth(txb);

    removeActionForTypeFromAgent(txb, [CAPSULE_BABY.$typeName, EDITOR.$typeName], {
      agent: await agent.getAddress(),
      auth,
      person: personId,
    });
    const _tx = await owner.signAndExecuteTransactionBlock({ transactionBlock: txb, options: { showEffects: true } });
  }

  claimDelegationAndEditBaby(agent, personId, babyId);
}

async function editBabyWithRemovedObjectAction({ owner, agent }: EditBabyWithAction) {
  const agentAddress = await agent.getAddress();
  const ownerAddress = await owner.getAddress();

  let personId: string = "",
    babyId: string = "";

  {
    const txb = new TransactionBlock();
    const [person, baby] = createPersonAndBaby(txb, ownerAddress, "Initial Baby name");

    returnAndSharePersonAndBaby(txb, person, baby);

    const _tx = await owner.signAndExecuteTransactionBlock({ transactionBlock: txb, options: { showEffects: true } });
  }

  {
    const txb = new TransactionBlock();
    const [auth] = beginTxAuth(txb);

    removeActionForObjectsFromAgent(txb, EDITOR.$typeName, {
      auth,
      person: personId,
      objects: [babyId],
      agent: agentAddress,
    });
    const _tx = await owner.signAndExecuteTransactionBlock({ transactionBlock: txb, options: { showEffects: true } });
  }

  {
    const txb = new TransactionBlock();
    const [auth] = beginTxAuth(txb);

    addActionForObjects(txb, EDITOR.$typeName, { agent: agentAddress, auth, person: personId, objects: [babyId] });

    const _tx = await owner.signAndExecuteTransactionBlock({ transactionBlock: txb, options: { showEffects: true } });
  }

  claimDelegationAndEditBaby(agent, personId, babyId);
}

function createPersonAndBaby(txb: TransactionBlock, guardian: string, babyName: string) {
  const [person] = createPerson(txb, guardian);
  const [baby] = createBaby(txb, babyName);

  return [person, baby];
}

function returnAndSharePersonAndBaby(txb: TransactionBlock, person: CallArg, baby: CallArg) {
  returnAndSharePerson(txb, person);
  returnAndShareBaby(txb, baby);
}

async function claimDelegationAndEditBaby(signer: RawSigner, person: CallArg, baby: CallArg) {
  const txb = new TransactionBlock();
  const [auth] = claimDelegation(txb, person);

  editBabyName(txb, { auth, baby, newName: "New Baby Name" });
  const _tx = await signer.signAndExecuteTransactionBlock({ transactionBlock: txb, options: { showEffects: true } });
}
