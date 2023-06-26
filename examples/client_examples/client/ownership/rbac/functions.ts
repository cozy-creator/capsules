import { PUBLISHED_AT } from "..";
import { ObjectArg, Type, obj, pure } from "../../_framework/util";
import { TransactionArgument, TransactionBlock } from "@mysten/sui.js";

export function create(
  txb: TransactionBlock,
  principal: string | TransactionArgument
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::rbac::create`,
    arguments: [pure(txb, principal, `address`)],
  });
}

export function principal(txb: TransactionBlock, rbac: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::rbac::principal`,
    arguments: [obj(txb, rbac)],
  });
}

export function agentRole(txb: TransactionBlock, rbac: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::rbac::agent_role`,
    arguments: [obj(txb, rbac)],
  });
}

export interface DeleteAgentArgs {
  rbac: ObjectArg;
  agent: string | TransactionArgument;
}

export function deleteAgent(txb: TransactionBlock, args: DeleteAgentArgs) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::rbac::delete_agent`,
    arguments: [obj(txb, args.rbac), pure(txb, args.agent, `address`)],
  });
}

export interface DeleteRoleAndAgentsArgs {
  rbac: ObjectArg;
  role: string | TransactionArgument;
}

export function deleteRoleAndAgents(
  txb: TransactionBlock,
  args: DeleteRoleAndAgentsArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::rbac::delete_role_and_agents`,
    arguments: [
      obj(txb, args.rbac),
      pure(txb, args.role, `0x1::string::String`),
    ],
  });
}

export interface GetAgentActionsArgs {
  rbac: ObjectArg;
  agent: string | TransactionArgument;
}

export function getAgentActions(
  txb: TransactionBlock,
  args: GetAgentActionsArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::rbac::get_agent_actions`,
    arguments: [obj(txb, args.rbac), pure(txb, args.agent, `address`)],
  });
}

export interface GrantActionToRoleArgs {
  rbac: ObjectArg;
  role: string | TransactionArgument;
}

export function grantActionToRole(
  txb: TransactionBlock,
  typeArg: Type,
  args: GrantActionToRoleArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::rbac::grant_action_to_role`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.rbac),
      pure(txb, args.role, `0x1::string::String`),
    ],
  });
}

export interface RevokeActionFromRoleArgs {
  rbac: ObjectArg;
  role: string | TransactionArgument;
}

export function revokeActionFromRole(
  txb: TransactionBlock,
  typeArg: Type,
  args: RevokeActionFromRoleArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::rbac::revoke_action_from_role`,
    typeArguments: [typeArg],
    arguments: [
      obj(txb, args.rbac),
      pure(txb, args.role, `0x1::string::String`),
    ],
  });
}

export function roleActions(txb: TransactionBlock, rbac: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::rbac::role_actions`,
    arguments: [obj(txb, rbac)],
  });
}

export interface SetRoleForAgentArgs {
  rbac: ObjectArg;
  agent: string | TransactionArgument;
  role: string | TransactionArgument;
}

export function setRoleForAgent(
  txb: TransactionBlock,
  args: SetRoleForAgentArgs
) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::rbac::set_role_for_agent`,
    arguments: [
      obj(txb, args.rbac),
      pure(txb, args.agent, `address`),
      pure(txb, args.role, `0x1::string::String`),
    ],
  });
}

export function toFields(txb: TransactionBlock, rbac: ObjectArg) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::rbac::to_fields`,
    arguments: [obj(txb, rbac)],
  });
}
