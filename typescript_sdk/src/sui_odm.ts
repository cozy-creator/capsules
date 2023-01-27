import { DevInspectResults, JsonRpcProvider, RawSigner } from "@mysten/sui.js";
import {publicKey, privateKeyBytes} from "./config";
import { Serializer } from "./serializer";

/**
 * Schema object configuration. Stores the on-chain schema id
 * This class is also responsible to call validator and ensure data complies with the schema
 */
class Schema {
    schema_id: string;

    constructor(schema_id: string) {
        this.schema_id = schema_id;
    }

};


/**
 * Base model class responsible for read and write on-chain
 */
class Model {
    schema: Schema;
    package_id: string;
    provider: JsonRpcProvider;
    signer: RawSigner;
    serializer: Serializer;

    constructor(schema: Schema, package_id: string, provider: JsonRpcProvider, signer: RawSigner, serializer: Serializer){
        this.schema = schema;
        this.package_id = package_id;
        this.provider = provider; 
        this.signer = signer;
        this.serializer = serializer;
    }   

    parseFetch(result: DevInspectResults): number[] {
        // @ts-ignore
        let data = result.results.Ok[0][1].returnValues[0][0] as number[];
        data.splice(0, 1);
        return data;
    }

    public async fetch(objIds: Array<string>) {
        const result = await this.provider.devInspectMoveCall(publicKey, {
            packageObjectId: this.package_id,
            module: 'outlaw_sky',
            function: 'view',
            typeArguments: [],
            arguments: objIds
          });
        const parsedData = this.parseFetch(result); 
        const deserializedData = this.serializer.deserialize(parsedData); 
        return deserializedData 
    };

    public create() {

    };

    public update() {

    }
};



class Provider {}