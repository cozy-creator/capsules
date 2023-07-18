import { bcsSource as bcs } from "../../../../_framework/bcs";
import { FieldsWithTypes, Type } from "../../../../_framework/util";
import { VecMap } from "../../0x2/vec-map/structs";
import { Action } from "../action/structs";
import { Encoding } from "@mysten/bcs";

/* ============================== RBAC =============================== */

bcs.registerStructType(
  "0xdcbadd322069f668204440a6245922a705922e9d1e061543c4bbf388d62d92db::rbac::RBAC",
  {
    principal: `address`,
    agent_role: `0x2::vec_map::VecMap<address, 0x1::string::String>`,
    role_actions: `0x2::vec_map::VecMap<0x1::string::String, vector<0xdcbadd322069f668204440a6245922a705922e9d1e061543c4bbf388d62d92db::action::Action>>`,
  },
);

export function isRBAC(type: Type): boolean {
  return (
    type ===
    "0xdcbadd322069f668204440a6245922a705922e9d1e061543c4bbf388d62d92db::rbac::RBAC"
  );
}

export interface RBACFields {
  principal: string;
  agentRole: VecMap<string, string>;
  roleActions: VecMap<string, Array<Action>>;
}

export class RBAC {
  static readonly $typeName =
    "0xdcbadd322069f668204440a6245922a705922e9d1e061543c4bbf388d62d92db::rbac::RBAC";
  static readonly $numTypeParams = 0;

  readonly principal: string;
  readonly agentRole: VecMap<string, string>;
  readonly roleActions: VecMap<string, Array<Action>>;

  constructor(fields: RBACFields) {
    this.principal = fields.principal;
    this.agentRole = fields.agentRole;
    this.roleActions = fields.roleActions;
  }

  static fromFields(fields: Record<string, any>): RBAC {
    return new RBAC({
      principal: `0x${fields.principal}`,
      agentRole: VecMap.fromFields<string, string>(
        [`address`, `0x1::string::String`],
        fields.agent_role,
      ),
      roleActions: VecMap.fromFields<string, Array<Action>>(
        [
          `0x1::string::String`,
          `vector<0xdcbadd322069f668204440a6245922a705922e9d1e061543c4bbf388d62d92db::action::Action>`,
        ],
        fields.role_actions,
      ),
    });
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): RBAC {
    if (!isRBAC(item.type)) {
      throw new Error("not a RBAC type");
    }
    return new RBAC({
      principal: `0x${item.fields.principal}`,
      agentRole: VecMap.fromFieldsWithTypes<string, string>(
        item.fields.agent_role,
      ),
      roleActions: VecMap.fromFieldsWithTypes<string, Array<Action>>(
        item.fields.role_actions,
      ),
    });
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): RBAC {
    return RBAC.fromFields(bcs.de([RBAC.$typeName], data, encoding));
  }
}
