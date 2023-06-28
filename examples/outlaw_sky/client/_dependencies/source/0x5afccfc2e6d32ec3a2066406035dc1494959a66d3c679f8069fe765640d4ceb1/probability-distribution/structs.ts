import { bcsSource as bcs } from "../../../../_framework/bcs"
import { FieldsWithTypes, Type } from "../../../../_framework/util"
import { Option } from "../../0x1/option/structs"
import { String } from "../../0x1/string/structs"
import { Encoding } from "@mysten/bcs"

/* ============================== ProbabilityDistribution =============================== */

bcs.registerStructType(
    "0x5afccfc2e6d32ec3a2066406035dc1494959a66d3c679f8069fe765640d4ceb1::probability_distribution::ProbabilityDistribution",
    {
        distribution: `0x1::string::String`,
        min: `u64`,
        max: `u64`,
        mean: `0x1::option::Option<u64>`,
        std_dev: `0x1::option::Option<u64>`,
        lambda: `0x1::option::Option<u64>`,
        weighted_high: `0x1::option::Option<bool>`,
    }
)

export function isProbabilityDistribution(type: Type): boolean {
    return (
        type ===
        "0x5afccfc2e6d32ec3a2066406035dc1494959a66d3c679f8069fe765640d4ceb1::probability_distribution::ProbabilityDistribution"
    )
}

export interface ProbabilityDistributionFields {
    distribution: string
    min: bigint
    max: bigint
    mean: bigint | null
    stdDev: bigint | null
    lambda: bigint | null
    weightedHigh: boolean | null
}

export class ProbabilityDistribution {
    static readonly $typeName =
        "0x5afccfc2e6d32ec3a2066406035dc1494959a66d3c679f8069fe765640d4ceb1::probability_distribution::ProbabilityDistribution"
    static readonly $numTypeParams = 0

    readonly distribution: string
    readonly min: bigint
    readonly max: bigint
    readonly mean: bigint | null
    readonly stdDev: bigint | null
    readonly lambda: bigint | null
    readonly weightedHigh: boolean | null

    constructor(fields: ProbabilityDistributionFields) {
        this.distribution = fields.distribution
        this.min = fields.min
        this.max = fields.max
        this.mean = fields.mean
        this.stdDev = fields.stdDev
        this.lambda = fields.lambda
        this.weightedHigh = fields.weightedHigh
    }

    static fromFields(fields: Record<string, any>): ProbabilityDistribution {
        return new ProbabilityDistribution({
            distribution: new TextDecoder()
                .decode(Uint8Array.from(String.fromFields(fields.distribution).bytes))
                .toString(),
            min: BigInt(fields.min),
            max: BigInt(fields.max),
            mean: Option.fromFields<bigint>(`u64`, fields.mean).vec[0] || null,
            stdDev: Option.fromFields<bigint>(`u64`, fields.std_dev).vec[0] || null,
            lambda: Option.fromFields<bigint>(`u64`, fields.lambda).vec[0] || null,
            weightedHigh: Option.fromFields<boolean>(`bool`, fields.weighted_high).vec[0] || null,
        })
    }

    static fromFieldsWithTypes(item: FieldsWithTypes): ProbabilityDistribution {
        if (!isProbabilityDistribution(item.type)) {
            throw new Error("not a ProbabilityDistribution type")
        }
        return new ProbabilityDistribution({
            distribution: item.fields.distribution,
            min: BigInt(item.fields.min),
            max: BigInt(item.fields.max),
            mean:
                item.fields.mean !== null
                    ? Option.fromFieldsWithTypes<bigint>({
                          type: "0x1::option::Option<" + `u64` + ">",
                          fields: { vec: [item.fields.mean] },
                      }).vec[0]
                    : null,
            stdDev:
                item.fields.std_dev !== null
                    ? Option.fromFieldsWithTypes<bigint>({
                          type: "0x1::option::Option<" + `u64` + ">",
                          fields: { vec: [item.fields.std_dev] },
                      }).vec[0]
                    : null,
            lambda:
                item.fields.lambda !== null
                    ? Option.fromFieldsWithTypes<bigint>({
                          type: "0x1::option::Option<" + `u64` + ">",
                          fields: { vec: [item.fields.lambda] },
                      }).vec[0]
                    : null,
            weightedHigh:
                item.fields.weighted_high !== null
                    ? Option.fromFieldsWithTypes<boolean>({
                          type: "0x1::option::Option<" + `bool` + ">",
                          fields: { vec: [item.fields.weighted_high] },
                      }).vec[0]
                    : null,
        })
    }

    static fromBcs(data: Uint8Array | string, encoding?: Encoding): ProbabilityDistribution {
        return ProbabilityDistribution.fromFields(
            bcs.de([ProbabilityDistribution.$typeName], data, encoding)
        )
    }
}
