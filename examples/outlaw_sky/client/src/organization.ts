import { RawSigner, TransactionBlock } from "@mysten/sui.js";
import {
  createFromReceipt,
  grantActionToRole,
  returnAndShare,
  revokeActionFromRole,
  setRoleForAgent,
} from "../ownership/organization/functions";
import { adminSigner, agentSigner, baseGasBudget, publishReceiptId } from "./config";
import { CREATOR, USER } from "../outlaw-sky/outlaw-sky/structs";
import { begin as beginTxAuth } from "../ownership/tx-authority/functions";

interface GrantActionToRole {
  signer: RawSigner;
  org: string;
  role: string;
  action: string;
}

interface SetRoleForAgent {
  agent: string;
  signer: RawSigner;
  org: string;
  role: string;
}

export async function createOrgFromReceipt(signer: RawSigner, receipt: string) {
  const txb = new TransactionBlock();
  const [org] = createFromReceipt(txb, { owner: await signer.getAddress(), receipt });
  returnAndShare(txb, org);
  txb.setGasBudget(baseGasBudget);

  return await signer.signAndExecuteTransactionBlock({ transactionBlock: txb, options: { showEffects: true } });
}

export async function grantOrgActionToRole({ action, signer, org, role }: GrantActionToRole) {
  const txb = new TransactionBlock();
  const [auth] = beginTxAuth(txb);

  grantActionToRole(txb, action, { auth, org, role });
  return await signer.signAndExecuteTransactionBlock({ transactionBlock: txb });
}

export async function setOrgRoleForAgent({ agent, signer, org, role }: SetRoleForAgent) {
  const txb = new TransactionBlock();
  const [auth] = beginTxAuth(txb);

  setRoleForAgent(txb, { agent, auth, org, role });
  return await signer.signAndExecuteTransactionBlock({ transactionBlock: txb });
}

export async function revokeActionFromOrgRole({ action, signer, org, role }: GrantActionToRole) {
  const txb = new TransactionBlock();
  const [auth] = beginTxAuth(txb);

  revokeActionFromRole(txb, action, { auth, org, role });
  return await signer.signAndExecuteTransactionBlock({ transactionBlock: txb });
}
