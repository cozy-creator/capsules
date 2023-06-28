import { PUBLISHED_AT } from ".."
import { ObjectArg, Type, obj, pure, vector } from "../../_framework/util"
import { ObjectId, TransactionArgument, TransactionBlock } from "@mysten/sui.js"

export function uid(txb: TransactionBlock, person: ObjectArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::person::uid`,
        arguments: [obj(txb, person)],
    })
}

export interface DestroyArgs {
    person: ObjectArg
    auth: ObjectArg
}

export function destroy(txb: TransactionBlock, args: DestroyArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::person::destroy`,
        arguments: [obj(txb, args.person), obj(txb, args.auth)],
    })
}

export function create(txb: TransactionBlock, guardian: string | TransactionArgument) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::person::create`,
        arguments: [pure(txb, guardian, `address`)],
    })
}

export function uidMut(txb: TransactionBlock, person: ObjectArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::person::uid_mut`,
        arguments: [obj(txb, person)],
    })
}

export interface Create_Args {
    principal: string | TransactionArgument
    guardian: string | TransactionArgument
    auth: ObjectArg
}

export function create_(txb: TransactionBlock, args: Create_Args) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::person::create_`,
        arguments: [
            pure(txb, args.principal, `address`),
            pure(txb, args.guardian, `address`),
            obj(txb, args.auth),
        ],
    })
}

export interface AddActionForObjectsArgs {
    person: ObjectArg
    agent: string | TransactionArgument
    objects: Array<ObjectId | TransactionArgument> | TransactionArgument
    auth: ObjectArg
}

export function addActionForObjects(
    txb: TransactionBlock,
    typeArg: Type,
    args: AddActionForObjectsArgs
) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::person::add_action_for_objects`,
        typeArguments: [typeArg],
        arguments: [
            obj(txb, args.person),
            pure(txb, args.agent, `address`),
            pure(txb, args.objects, `vector<0x2::object::ID>`),
            obj(txb, args.auth),
        ],
    })
}

export interface AddActionForTypesArgs {
    person: ObjectArg
    agent: string | TransactionArgument
    types: Array<ObjectArg> | TransactionArgument
    auth: ObjectArg
}

export function addActionForTypes(
    txb: TransactionBlock,
    typeArg: Type,
    args: AddActionForTypesArgs
) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::person::add_action_for_types`,
        typeArguments: [typeArg],
        arguments: [
            obj(txb, args.person),
            pure(txb, args.agent, `address`),
            vector(
                txb,
                `0xfbf59d4ea15bc2da870cd74991503ae3c504bb108061ba5d7270fd0bb0be00b2::struct_tag::StructTag`,
                args.types
            ),
            obj(txb, args.auth),
        ],
    })
}

export function principal(txb: TransactionBlock, person: ObjectArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::person::principal`,
        arguments: [obj(txb, person)],
    })
}

export interface AgentActionsArgs {
    person: ObjectArg
    agent: string | TransactionArgument
}

export function agentActions(txb: TransactionBlock, args: AgentActionsArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::person::agent_actions`,
        arguments: [obj(txb, args.person), pure(txb, args.agent, `address`)],
    })
}

export function returnAndShare(txb: TransactionBlock, person: ObjectArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::person::return_and_share`,
        arguments: [obj(txb, person)],
    })
}

export interface AddActionForTypeArgs {
    person: ObjectArg
    agent: string | TransactionArgument
    auth: ObjectArg
}

export function addActionForType(
    txb: TransactionBlock,
    typeArgs: [Type, Type],
    args: AddActionForTypeArgs
) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::person::add_action_for_type`,
        typeArguments: typeArgs,
        arguments: [obj(txb, args.person), pure(txb, args.agent, `address`), obj(txb, args.auth)],
    })
}

export interface AddGeneralActionArgs {
    person: ObjectArg
    agent: string | TransactionArgument
    auth: ObjectArg
}

export function addGeneralAction(txb: TransactionBlock, typeArg: Type, args: AddGeneralActionArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::person::add_general_action`,
        typeArguments: [typeArg],
        arguments: [obj(txb, args.person), pure(txb, args.agent, `address`), obj(txb, args.auth)],
    })
}

export interface AgentActionsMutArgs {
    person: ObjectArg
    agent: string | TransactionArgument
}

export function agentActionsMut(txb: TransactionBlock, args: AgentActionsMutArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::person::agent_actions_mut`,
        arguments: [obj(txb, args.person), pure(txb, args.agent, `address`)],
    })
}

export interface AgentActionsValueArgs {
    person: ObjectArg
    agent: string | TransactionArgument
}

export function agentActionsValue(txb: TransactionBlock, args: AgentActionsValueArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::person::agent_actions_value`,
        arguments: [obj(txb, args.person), pure(txb, args.agent, `address`)],
    })
}

export function claimDelegation(txb: TransactionBlock, person: ObjectArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::person::claim_delegation`,
        arguments: [obj(txb, person)],
    })
}

export interface ClaimDelegation_Args {
    person: ObjectArg
    agent: string | TransactionArgument
    auth: ObjectArg
}

export function claimDelegation_(txb: TransactionBlock, args: ClaimDelegation_Args) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::person::claim_delegation_`,
        arguments: [obj(txb, args.person), pure(txb, args.agent, `address`), obj(txb, args.auth)],
    })
}

export function guardian(txb: TransactionBlock, person: ObjectArg) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::person::guardian`,
        arguments: [obj(txb, person)],
    })
}

export interface RemoveActionForObjectsFromAgentArgs {
    person: ObjectArg
    agent: string | TransactionArgument
    objects: Array<ObjectId | TransactionArgument> | TransactionArgument
    auth: ObjectArg
}

export function removeActionForObjectsFromAgent(
    txb: TransactionBlock,
    typeArg: Type,
    args: RemoveActionForObjectsFromAgentArgs
) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::person::remove_action_for_objects_from_agent`,
        typeArguments: [typeArg],
        arguments: [
            obj(txb, args.person),
            pure(txb, args.agent, `address`),
            pure(txb, args.objects, `vector<0x2::object::ID>`),
            obj(txb, args.auth),
        ],
    })
}

export interface RemoveActionForTypeFromAgentArgs {
    person: ObjectArg
    agent: string | TransactionArgument
    auth: ObjectArg
}

export function removeActionForTypeFromAgent(
    txb: TransactionBlock,
    typeArgs: [Type, Type],
    args: RemoveActionForTypeFromAgentArgs
) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::person::remove_action_for_type_from_agent`,
        typeArguments: typeArgs,
        arguments: [obj(txb, args.person), pure(txb, args.agent, `address`), obj(txb, args.auth)],
    })
}

export interface RemoveActionForTypesFromAgentArgs {
    person: ObjectArg
    agent: string | TransactionArgument
    types: Array<ObjectArg> | TransactionArgument
    auth: ObjectArg
}

export function removeActionForTypesFromAgent(
    txb: TransactionBlock,
    typeArg: Type,
    args: RemoveActionForTypesFromAgentArgs
) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::person::remove_action_for_types_from_agent`,
        typeArguments: [typeArg],
        arguments: [
            obj(txb, args.person),
            pure(txb, args.agent, `address`),
            vector(
                txb,
                `0xfbf59d4ea15bc2da870cd74991503ae3c504bb108061ba5d7270fd0bb0be00b2::struct_tag::StructTag`,
                args.types
            ),
            obj(txb, args.auth),
        ],
    })
}

export interface RemoveAgentArgs {
    person: ObjectArg
    agent: string | TransactionArgument
    auth: ObjectArg
}

export function removeAgent(txb: TransactionBlock, args: RemoveAgentArgs) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::person::remove_agent`,
        arguments: [obj(txb, args.person), pure(txb, args.agent, `address`), obj(txb, args.auth)],
    })
}

export interface RemoveAllActionsForObjectsFromAgentArgs {
    person: ObjectArg
    agent: string | TransactionArgument
    objects: Array<ObjectId | TransactionArgument> | TransactionArgument
    auth: ObjectArg
}

export function removeAllActionsForObjectsFromAgent(
    txb: TransactionBlock,
    args: RemoveAllActionsForObjectsFromAgentArgs
) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::person::remove_all_actions_for_objects_from_agent`,
        arguments: [
            obj(txb, args.person),
            pure(txb, args.agent, `address`),
            pure(txb, args.objects, `vector<0x2::object::ID>`),
            obj(txb, args.auth),
        ],
    })
}

export interface RemoveAllActionsForTypeFromAgentArgs {
    person: ObjectArg
    agent: string | TransactionArgument
    auth: ObjectArg
}

export function removeAllActionsForTypeFromAgent(
    txb: TransactionBlock,
    typeArg: Type,
    args: RemoveAllActionsForTypeFromAgentArgs
) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::person::remove_all_actions_for_type_from_agent`,
        typeArguments: [typeArg],
        arguments: [obj(txb, args.person), pure(txb, args.agent, `address`), obj(txb, args.auth)],
    })
}

export interface RemoveAllActionsForTypesFromAgentArgs {
    person: ObjectArg
    agent: string | TransactionArgument
    types: Array<ObjectArg> | TransactionArgument
    auth: ObjectArg
}

export function removeAllActionsForTypesFromAgent(
    txb: TransactionBlock,
    args: RemoveAllActionsForTypesFromAgentArgs
) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::person::remove_all_actions_for_types_from_agent`,
        arguments: [
            obj(txb, args.person),
            pure(txb, args.agent, `address`),
            vector(
                txb,
                `0xfbf59d4ea15bc2da870cd74991503ae3c504bb108061ba5d7270fd0bb0be00b2::struct_tag::StructTag`,
                args.types
            ),
            obj(txb, args.auth),
        ],
    })
}

export interface RemoveAllGeneralActionsFromAgentArgs {
    person: ObjectArg
    agent: string | TransactionArgument
    auth: ObjectArg
}

export function removeAllGeneralActionsFromAgent(
    txb: TransactionBlock,
    args: RemoveAllGeneralActionsFromAgentArgs
) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::person::remove_all_general_actions_from_agent`,
        arguments: [obj(txb, args.person), pure(txb, args.agent, `address`), obj(txb, args.auth)],
    })
}

export interface RemoveGeneralActionFromAgentArgs {
    person: ObjectArg
    agent: string | TransactionArgument
    auth: ObjectArg
}

export function removeGeneralActionFromAgent(
    txb: TransactionBlock,
    typeArg: Type,
    args: RemoveGeneralActionFromAgentArgs
) {
    return txb.moveCall({
        target: `${PUBLISHED_AT}::person::remove_general_action_from_agent`,
        typeArguments: [typeArg],
        arguments: [obj(txb, args.person), pure(txb, args.agent, `address`), obj(txb, args.auth)],
    })
}
