import { bcsSource as bcs } from "../../../../_framework/bcs";
import { FieldsWithTypes, Type } from "../../../../_framework/util";
import { VecMap } from "../../0x2/vec-map/structs";
import { StructTag } from "../../0x6adaf7f9c1f7ae68b96dc85f5b069f4a6aabc748d8d741184ca5479fb4466bae/struct-tag/structs";
import { Action } from "../action/structs";
import { Encoding } from "@mysten/bcs";
import { ObjectId } from "@mysten/sui.js";

/* ============================== ActionSet =============================== */

bcs.registerStructType(
  "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::action_set::ActionSet",
  {
    general: `vector<0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::action::Action>`,
    on_types: `0x2::vec_map::VecMap<0x6adaf7f9c1f7ae68b96dc85f5b069f4a6aabc748d8d741184ca5479fb4466bae::struct_tag::StructTag, vector<0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::action::Action>>`,
    on_objects: `0x2::vec_map::VecMap<0x2::object::ID, vector<0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::action::Action>>`,
  },
);

export function isActionSet(type: Type): boolean {
  return (
    type ===
    "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::action_set::ActionSet"
  );
}

export interface ActionSetFields {
  general: Array<Action>;
  onTypes: VecMap<StructTag, Array<Action>>;
  onObjects: VecMap<ObjectId, Array<Action>>;
}

export class ActionSet {
  static readonly $typeName =
    "0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::action_set::ActionSet";
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
          `0x6adaf7f9c1f7ae68b96dc85f5b069f4a6aabc748d8d741184ca5479fb4466bae::struct_tag::StructTag`,
          `vector<0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::action::Action>`,
        ],
        fields.on_types,
      ),
      onObjects: VecMap.fromFields<ObjectId, Array<Action>>(
        [
          `0x2::object::ID`,
          `vector<0x9b66045cbf367d4ce152b30df727556aa0d7c192b4ade762571fac260ac8274a::action::Action>`,
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
