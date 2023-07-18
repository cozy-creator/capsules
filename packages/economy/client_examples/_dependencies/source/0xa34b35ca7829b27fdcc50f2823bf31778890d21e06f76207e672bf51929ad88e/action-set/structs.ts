import { bcsSource as bcs } from "../../../../_framework/bcs";
import { FieldsWithTypes, Type } from "../../../../_framework/util";
import { VecMap } from "../../0x2/vec-map/structs";
import { StructTag } from "../../0xa18d9e5ffabf8a361289adfcdbeef4a11e5ef79bb34ca36ab7ca3e7f0a6a8619/struct-tag/structs";
import { Action } from "../action/structs";
import { Encoding } from "@mysten/bcs";
import { ObjectId } from "@mysten/sui.js";

/* ============================== ActionSet =============================== */

bcs.registerStructType(
  "0xa34b35ca7829b27fdcc50f2823bf31778890d21e06f76207e672bf51929ad88e::action_set::ActionSet",
  {
    general: `vector<0xa34b35ca7829b27fdcc50f2823bf31778890d21e06f76207e672bf51929ad88e::action::Action>`,
    on_types: `0x2::vec_map::VecMap<0xa18d9e5ffabf8a361289adfcdbeef4a11e5ef79bb34ca36ab7ca3e7f0a6a8619::struct_tag::StructTag, vector<0xa34b35ca7829b27fdcc50f2823bf31778890d21e06f76207e672bf51929ad88e::action::Action>>`,
    on_objects: `0x2::vec_map::VecMap<0x2::object::ID, vector<0xa34b35ca7829b27fdcc50f2823bf31778890d21e06f76207e672bf51929ad88e::action::Action>>`,
  },
);

export function isActionSet(type: Type): boolean {
  return (
    type ===
    "0xa34b35ca7829b27fdcc50f2823bf31778890d21e06f76207e672bf51929ad88e::action_set::ActionSet"
  );
}

export interface ActionSetFields {
  general: Array<Action>;
  onTypes: VecMap<StructTag, Array<Action>>;
  onObjects: VecMap<ObjectId, Array<Action>>;
}

export class ActionSet {
  static readonly $typeName =
    "0xa34b35ca7829b27fdcc50f2823bf31778890d21e06f76207e672bf51929ad88e::action_set::ActionSet";
  static readonly $numTypeParams = 0;

  readonly general: Array<Action>;
  readonly onTypes: VecMap<StructTag, Array<Action>>;
  readonly onObjects: VecMap<ObjectId, Array<Action>>;

  constructor(fields: ActionSetFields) {
    this.general = fields.general;
    this.onTypes = fields.onTypes;
    this.onObjects = fields.onObjects;
  }

  static fromFields(fields: Record<string, any>): ActionSet {
    return new ActionSet({
      general: fields.general.map((item: any) => Action.fromFields(item)),
      onTypes: VecMap.fromFields<StructTag, Array<Action>>(
        [
          `0xa18d9e5ffabf8a361289adfcdbeef4a11e5ef79bb34ca36ab7ca3e7f0a6a8619::struct_tag::StructTag`,
          `vector<0xa34b35ca7829b27fdcc50f2823bf31778890d21e06f76207e672bf51929ad88e::action::Action>`,
        ],
        fields.on_types,
      ),
      onObjects: VecMap.fromFields<ObjectId, Array<Action>>(
        [
          `0x2::object::ID`,
          `vector<0xa34b35ca7829b27fdcc50f2823bf31778890d21e06f76207e672bf51929ad88e::action::Action>`,
        ],
        fields.on_objects,
      ),
    });
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): ActionSet {
    if (!isActionSet(item.type)) {
      throw new Error("not a ActionSet type");
    }
    return new ActionSet({
      general: item.fields.general.map((item: any) =>
        Action.fromFieldsWithTypes(item),
      ),
      onTypes: VecMap.fromFieldsWithTypes<StructTag, Array<Action>>(
        item.fields.on_types,
      ),
      onObjects: VecMap.fromFieldsWithTypes<ObjectId, Array<Action>>(
        item.fields.on_objects,
      ),
    });
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): ActionSet {
    return ActionSet.fromFields(bcs.de([ActionSet.$typeName], data, encoding));
  }
}
