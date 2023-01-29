import { DevInspectResults, JsonRpcProvider, RawSigner } from "@mysten/sui.js";
import {publicKey, privateKeyBytes} from "./config";
import { Serializer } from "./serializer";
import { Validator } from "./validator";

/**
 * Schema object configuration. Stores the on-chain schema id
 * This class is also responsible to call validator and ensure data complies with the schema
 */
export class Schema {
    schema_id: string;
    schemaObj: Record<string, string>;
    validator: Validator;

    constructor(schema_id: string, schemaObj: Record<string, string>) {
        this.schema_id = schema_id;
        this.schemaObj = schemaObj
        this.validator = new Validator(this.schemaObj);
    }

    public check(data: object) {
        this.validator.check(data);
    }
};


/**
 * Base model class responsible for read and write on-chain
 */
export class Model {
    schema: Schema;
    package_id: string;
    provider: JsonRpcProvider;
    signer: RawSigner;
    serializer: Serializer;
    module: string;

    constructor(schema: Schema, package_id: string, provider: JsonRpcProvider, signer: RawSigner, serializer: Serializer, module: string){
        this.schema = schema;
        this.package_id = package_id;
        this.provider = provider; 
        this.signer = signer;
        this.serializer = serializer;
        this.module = module;
    }   

    parseFetch(result: DevInspectResults): number[] {
        // @ts-ignore
        let data = result.results.Ok[0][1].returnValues[0][0] as number[];
        data.splice(0, 1);
        return data;
    }

    public async fetch(objectId: string) {
        const result = await this.provider.devInspectMoveCall(publicKey, {
            packageObjectId: this.package_id,
            module: this.module,
            function: 'view',
            typeArguments: [],
            arguments: [objectId, this.schema.schema_id]
          });
        const parsedData = this.parseFetch(result); 
        const deserializedData = this.serializer.deserialize(parsedData); 
        this.schema.check(deserializedData);
        return deserializedData 
    };

    public async create(data: object) {
        this.schema.check(data);
        const serialized_data = this.serializer.serialize(data)
        const moveCallTxn = await this.signer.executeMoveCall({
            packageObjectId: this.package_id,
            module: this.module,
            function: 'create',
            typeArguments: [],
            arguments: [this.schema.schema_id, serialized_data],
            gasBudget: 15000
          });
    };

    public async update(objectId: string, keysToUpdate: string[], data: object) {
        this.schema.check(data);
        const serialized_data = this.serializer.serialize(data)
        const moveCallTxn = await this.signer.executeMoveCall({
            packageObjectId: this.package_id,
            module: this.module,
            function: 'overwrite',
            typeArguments: [],
            arguments: [objectId, keysToUpdate, serialized_data, this.schema.schema_id],
            gasBudget: 15000
          });
    }
};
