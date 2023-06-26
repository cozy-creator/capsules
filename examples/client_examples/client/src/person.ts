import { RawSigner, TransactionBlock } from "@mysten/sui.js";
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
  let personId: string = "",
    babyId: string = "";

  {
    const txb = new TransactionBlock();
    const [person] = createPerson(txb, await owner.getAddress());
    const [baby] = createBaby(txb, "Initial Baby Name");
    const [auth] = beginTxAuth(txb);

    addGeneralAction(txb, EDITOR.$typeName, { agent: await agent.getAddress(), auth, person });
    returnAndSharePerson(txb, person);
    returnAndShareBaby(txb, baby);

    const _tx = await owner.signAndExecuteTransactionBlock({ transactionBlock: txb, options: { showEffects: true } });
  }

  {
    const txb = new TransactionBlock();
    const [auth] = claimDelegation(txb, personId);

    editBabyName(txb, { auth, baby: babyId, newName: "New Baby Name" });
    const _tx = await agent.signAndExecuteTransactionBlock({ transactionBlock: txb, options: { showEffects: true } });
  }
}

async function editBabyWithTypeAction({ owner, agent }: EditBabyWithAction) {
  let personId: string = "",
    babyId: string = "";

  {
    const txb = new TransactionBlock();
    const [person] = createPerson(txb, await owner.getAddress());
    const [baby] = createBaby(txb, "Initial Baby Name");
    const [auth] = beginTxAuth(txb);

    addActionForType(txb, [CAPSULE_BABY.$typeName, EDITOR.$typeName], {
      agent: await agent.getAddress(),
      auth,
      person,
    });
    returnAndSharePerson(txb, person);
    returnAndShareBaby(txb, baby);

    const _tx = await owner.signAndExecuteTransactionBlock({ transactionBlock: txb, options: { showEffects: true } });
  }

  {
    const txb = new TransactionBlock();
    const [auth] = claimDelegation(txb, personId);

    editBabyName(txb, { auth, baby: babyId, newName: "New Baby Name" });
    const _tx = await agent.signAndExecuteTransactionBlock({ transactionBlock: txb, options: { showEffects: true } });
  }
}

async function editBabyWithObjectAction({ owner, agent }: EditBabyWithAction) {
  let personId: string = "",
    babyId: string = "";

  {
    const txb = new TransactionBlock();
    const [person] = createPerson(txb, await owner.getAddress());
    const [baby] = createBaby(txb, "Initial Baby Name");

    returnAndSharePerson(txb, person);
    returnAndShareBaby(txb, baby);

    const _tx = await owner.signAndExecuteTransactionBlock({ transactionBlock: txb, options: { showEffects: true } });
  }

  {
    const txb = new TransactionBlock();
    const [auth] = beginTxAuth(txb);

    addActionForObjects(txb, EDITOR.$typeName, {
      agent: await agent.getAddress(),
      auth,
      person: personId,
      objects: [babyId],
    });

    const _tx = await owner.signAndExecuteTransactionBlock({ transactionBlock: txb, options: { showEffects: true } });
  }

  {
    const txb = new TransactionBlock();
    const [auth] = claimDelegation(txb, personId);

    editBabyName(txb, { auth, baby: babyId, newName: "New Baby Name" });
    const _tx = await agent.signAndExecuteTransactionBlock({ transactionBlock: txb, options: { showEffects: true } });
  }
}

async function editBabyWithEmptyAction({ owner, agent }: EditBabyWithAction) {
  let personId: string = "",
    babyId: string = "";

  {
    const txb = new TransactionBlock();
    const [person] = createPerson(txb, await owner.getAddress());
    const [baby] = createBaby(txb, "Initial Baby Name");

    returnAndSharePerson(txb, person);
    returnAndShareBaby(txb, baby);

    const _tx = await owner.signAndExecuteTransactionBlock({ transactionBlock: txb, options: { showEffects: true } });
  }

  {
    const txb = new TransactionBlock();
    const [auth] = claimDelegation(txb, personId);

    editBabyName(txb, { auth, baby: babyId, newName: "New Baby Name" });
    const _tx = await agent.signAndExecuteTransactionBlock({ transactionBlock: txb, options: { showEffects: true } });
  }
}

async function editBabyWithRemovedGeneralAction({ owner, agent }: EditBabyWithAction) {
  let personId: string = "",
    babyId: string = "";

  {
    const txb = new TransactionBlock();
    const [person] = createPerson(txb, await owner.getAddress());
    const [baby] = createBaby(txb, "Initial Baby Name");
    const [auth] = beginTxAuth(txb);

    addGeneralAction(txb, EDITOR.$typeName, { agent: await agent.getAddress(), auth, person });

    returnAndSharePerson(txb, person);
    returnAndShareBaby(txb, baby);

    const _tx = await owner.signAndExecuteTransactionBlock({ transactionBlock: txb, options: { showEffects: true } });
  }

  {
    const txb = new TransactionBlock();
    const [auth] = beginTxAuth(txb);

    removeGeneralActionFromAgent(txb, EDITOR.$typeName, { agent: await agent.getAddress(), auth, person: personId });
    const _tx = await owner.signAndExecuteTransactionBlock({ transactionBlock: txb, options: { showEffects: true } });
  }

  {
    const txb = new TransactionBlock();
    const [auth] = claimDelegation(txb, personId);

    editBabyName(txb, { auth, baby: babyId, newName: "New Baby Name" });
    const _tx = await agent.signAndExecuteTransactionBlock({ transactionBlock: txb, options: { showEffects: true } });
  }
}

async function editBabyWithRemovedTypeAction({ owner, agent }: EditBabyWithAction) {
  let personId: string = "",
    babyId: string = "";

  {
    const txb = new TransactionBlock();
    const [person] = createPerson(txb, await owner.getAddress());
    const [baby] = createBaby(txb, "Initial Baby Name");
    const [auth] = beginTxAuth(txb);

    addActionForType(txb, [CAPSULE_BABY.$typeName, EDITOR.$typeName], {
      agent: await agent.getAddress(),
      auth,
      person,
    });
    returnAndSharePerson(txb, person);
    returnAndShareBaby(txb, baby);

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

  {
    const txb = new TransactionBlock();
    const [auth] = claimDelegation(txb, personId);

    editBabyName(txb, { auth, baby: babyId, newName: "New Baby Name" });
    const _tx = await agent.signAndExecuteTransactionBlock({ transactionBlock: txb, options: { showEffects: true } });
  }
}

async function editBabyWithRemovedObjectAction({ owner, agent }: EditBabyWithAction) {
  let personId: string = "",
    babyId: string = "";

  {
    const txb = new TransactionBlock();
    const [person] = createPerson(txb, await owner.getAddress());
    const [baby] = createBaby(txb, "Initial Baby Name");

    returnAndSharePerson(txb, person);
    returnAndShareBaby(txb, baby);

    const _tx = await owner.signAndExecuteTransactionBlock({ transactionBlock: txb, options: { showEffects: true } });
  }

  {
    const txb = new TransactionBlock();
    const [auth] = beginTxAuth(txb);

    removeActionForObjectsFromAgent(txb, EDITOR.$typeName, {
      agent: await agent.getAddress(),
      auth,
      person: personId,
      objects: [babyId],
    });
    const _tx = await owner.signAndExecuteTransactionBlock({ transactionBlock: txb, options: { showEffects: true } });
  }

  {
    const txb = new TransactionBlock();
    const [auth] = beginTxAuth(txb);

    addActionForObjects(txb, EDITOR.$typeName, {
      agent: await agent.getAddress(),
      auth,
      person: personId,
      objects: [babyId],
    });

    const _tx = await owner.signAndExecuteTransactionBlock({ transactionBlock: txb, options: { showEffects: true } });
  }

  {
    const txb = new TransactionBlock();
    const [auth] = claimDelegation(txb, personId);

    editBabyName(txb, { auth, baby: babyId, newName: "New Baby Name" });
    const _tx = await agent.signAndExecuteTransactionBlock({ transactionBlock: txb, options: { showEffects: true } });
  }
}
