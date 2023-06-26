import { VecMap } from "../../_dependencies/source/0x2/vec-map/structs";
import { StructTag } from "../../_dependencies/source/0xfcb0f4008277fc0703d09b7e1245918ce5c9b6f9f65a42eed806430903d72946/struct-tag/structs";
import { bcsSource as bcs } from "../../_framework/bcs";
import { FieldsWithTypes, Type } from "../../_framework/util";
import { Action } from "../action/structs";
import { Encoding } from "@mysten/bcs";
import { ObjectId } from "@mysten/sui.js";

/* ============================== ActionSet =============================== */

bcs.registerStructType(
  "0xf167c2f8449be4da16dcf9633206228068d672f2dd2d8d8d06c5cac90dc3d1ac::action_set::ActionSet",
  {
    general: `vector<0xf167c2f8449be4da16dcf9633206228068d672f2dd2d8d8d06c5cac90dc3d1ac::action::Action>`,
    on_types: `0x2::vec_map::VecMap<0xfcb0f4008277fc0703d09b7e1245918ce5c9b6f9f65a42eed806430903d72946::struct_tag::StructTag, vector<0xf167c2f8449be4da16dcf9633206228068d672f2dd2d8d8d06c5cac90dc3d1ac::action::Action>>`,
    on_objects: `0x2::vec_map::VecMap<0x2::object::ID, vector<0xf167c2f8449be4da16dcf9633206228068d672f2dd2d8d8d06c5cac90dc3d1ac::action::Action>>`,
  }
);

export function isActionSet(type: Type): boolean {
  return (
    type ===
    "0xf167c2f8449be4da16dcf9633206228068d672f2dd2d8d8d06c5cac90dc3d1ac::action_set::ActionSet"
  );
}

export interface ActionSetFields {
  general: Array<Action>;
  onTypes: VecMap<StructTag, Array<Action>>;
  onObjects: VecMap<ObjectId, Array<Action>>;
}

export class ActionSet {
  static readonly $typeName =
    "0xf167c2f8449be4da16dcf9633206228068d672f2dd2d8d8d06c5cac90dc3d1ac::action_set::ActionSet";
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
          `0xfcb0f4008277fc0703d09b7e1245918ce5c9b6f9f65a42eed806430903d72946::struct_tag::StructTag`,
          `vector<0xf167c2f8449be4da16dcf9633206228068d672f2dd2d8d8d06c5cac90dc3d1ac::action::Action>`,
        ],
        fields.on_types
      ),
      onObjects: VecMap.fromFields<ObjectId, Array<Action>>(
        [
          `0x2::object::ID`,
          `vector<0xf167c2f8449be4da16dcf9633206228068d672f2dd2d8d8d06c5cac90dc3d1ac::action::Action>`,
        ],
        fields.on_objects
      ),
    });
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): ActionSet {
    if (!isActionSet(item.type)) {
      throw new Error("not a ActionSet type");
    }
    return new ActionSet({
      general: item.fields.general.map((item: any) =>
        Action.fromFieldsWithTypes(item)
      ),
      onTypes: VecMap.fromFieldsWithTypes<StructTag, Array<Action>>(
        item.fields.on_types
      ),
      onObjects: VecMap.fromFieldsWithTypes<ObjectId, Array<Action>>(
        item.fields.on_objects
      ),
    });
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): ActionSet {
    return ActionSet.fromFields(bcs.de([ActionSet.$typeName], data, encoding));
  }
}
