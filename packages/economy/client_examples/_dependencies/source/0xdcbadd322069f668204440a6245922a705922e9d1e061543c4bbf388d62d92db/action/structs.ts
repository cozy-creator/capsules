import { bcsSource as bcs } from "../../../../_framework/bcs";
import { FieldsWithTypes, Type } from "../../../../_framework/util";
import { String } from "../../0x1/string/structs";
import { Encoding } from "@mysten/bcs";

/* ============================== ADMIN =============================== */

bcs.registerStructType(
  "0xdcbadd322069f668204440a6245922a705922e9d1e061543c4bbf388d62d92db::action::ADMIN",
  {
    dummy_field: `bool`,
  },
);

export function isADMIN(type: Type): boolean {
  return (
    type ===
    "0xdcbadd322069f668204440a6245922a705922e9d1e061543c4bbf388d62d92db::action::ADMIN"
  );
}

export interface ADMINFields {
  dummyField: boolean;
}

export class ADMIN {
  static readonly $typeName =
    "0xdcbadd322069f668204440a6245922a705922e9d1e061543c4bbf388d62d92db::action::ADMIN";
  static readonly $numTypeParams = 0;

  readonly dummyField: boolean;

  constructor(dummyField: boolean) {
    this.dummyField = dummyField;
  }

  static fromFields(fields: Record<string, any>): ADMIN {
    return new ADMIN(fields.dummy_field);
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): ADMIN {
    if (!isADMIN(item.type)) {
      throw new Error("not a ADMIN type");
    }
    return new ADMIN(item.fields.dummy_field);
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): ADMIN {
    return ADMIN.fromFields(bcs.de([ADMIN.$typeName], data, encoding));
  }
}

/* ============================== ANY =============================== */

bcs.registerStructType(
  "0xdcbadd322069f668204440a6245922a705922e9d1e061543c4bbf388d62d92db::action::ANY",
  {
    dummy_field: `bool`,
  },
);

export function isANY(type: Type): boolean {
  return (
    type ===
    "0xdcbadd322069f668204440a6245922a705922e9d1e061543c4bbf388d62d92db::action::ANY"
  );
}

export interface ANYFields {
  dummyField: boolean;
}

export class ANY {
  static readonly $typeName =
    "0xdcbadd322069f668204440a6245922a705922e9d1e061543c4bbf388d62d92db::action::ANY";
  static readonly $numTypeParams = 0;

  readonly dummyField: boolean;

  constructor(dummyField: boolean) {
    this.dummyField = dummyField;
  }

  static fromFields(fields: Record<string, any>): ANY {
    return new ANY(fields.dummy_field);
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): ANY {
    if (!isANY(item.type)) {
      throw new Error("not a ANY type");
    }
    return new ANY(item.fields.dummy_field);
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): ANY {
    return ANY.fromFields(bcs.de([ANY.$typeName], data, encoding));
  }
}

/* ============================== Action =============================== */

bcs.registerStructType(
  "0xdcbadd322069f668204440a6245922a705922e9d1e061543c4bbf388d62d92db::action::Action",
  {
    inner: `0x1::string::String`,
  },
);

export function isAction(type: Type): boolean {
  return (
    type ===
    "0xdcbadd322069f668204440a6245922a705922e9d1e061543c4bbf388d62d92db::action::Action"
  );
}

export interface ActionFields {
  inner: string;
}

export class Action {
  static readonly $typeName =
    "0xdcbadd322069f668204440a6245922a705922e9d1e061543c4bbf388d62d92db::action::Action";
  static readonly $numTypeParams = 0;

  readonly inner: string;

  constructor(inner: string) {
    this.inner = inner;
  }

  static fromFields(fields: Record<string, any>): Action {
    return new Action(
      new TextDecoder()
        .decode(Uint8Array.from(String.fromFields(fields.inner).bytes))
        .toString(),
    );
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): Action {
    if (!isAction(item.type)) {
      throw new Error("not a Action type");
    }
    return new Action(item.fields.inner);
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): Action {
    return Action.fromFields(bcs.de([Action.$typeName], data, encoding));
  }
}

/* ============================== MANAGER =============================== */

bcs.registerStructType(
  "0xdcbadd322069f668204440a6245922a705922e9d1e061543c4bbf388d62d92db::action::MANAGER",
  {
    dummy_field: `bool`,
  },
);

export function isMANAGER(type: Type): boolean {
  return (
    type ===
    "0xdcbadd322069f668204440a6245922a705922e9d1e061543c4bbf388d62d92db::action::MANAGER"
  );
}

export interface MANAGERFields {
  dummyField: boolean;
}

export class MANAGER {
  static readonly $typeName =
    "0xdcbadd322069f668204440a6245922a705922e9d1e061543c4bbf388d62d92db::action::MANAGER";
  static readonly $numTypeParams = 0;

  readonly dummyField: boolean;

  constructor(dummyField: boolean) {
    this.dummyField = dummyField;
  }

  static fromFields(fields: Record<string, any>): MANAGER {
    return new MANAGER(fields.dummy_field);
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): MANAGER {
    if (!isMANAGER(item.type)) {
      throw new Error("not a MANAGER type");
    }
    return new MANAGER(item.fields.dummy_field);
  }

  static fromBcs(data: Uint8Array | string, encoding?: Encoding): MANAGER {
    return MANAGER.fromFields(bcs.de([MANAGER.$typeName], data, encoding));
  }
}
