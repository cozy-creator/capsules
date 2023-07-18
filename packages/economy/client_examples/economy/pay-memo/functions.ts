import { PUBLISHED_AT } from "..";
import { pure } from "../../_framework/util";
import {
  ObjectId,
  TransactionArgument,
  TransactionBlock,
} from "@mysten/sui.js";

export interface EmitArgs {
  referenceId: ObjectId | TransactionArgument;
  merchant: string | TransactionArgument;
  description: string | TransactionArgument;
}

export function emit(txb: TransactionBlock, args: EmitArgs) {
  return txb.moveCall({
    target: `${PUBLISHED_AT}::pay_memo::emit`,
    arguments: [
      pure(txb, args.referenceId, `0x2::object::ID`),
      pure(txb, args.merchant, `0x1::string::String`),
      pure(txb, args.description, `0x1::string::String`),
    ],
  });
}
