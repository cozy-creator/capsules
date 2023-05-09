// For normal and exponential distributions, if x falls outside of our (min, max) range, we simply truncate
// the range, rather than re-sampling until we get an in-range value.

module sui_utils::probability_distribution {
    use std::option::{Self, Option};
    use std::string::{Self, String};

    use sui::math::{max, min};
    use sui::tx_context::TxContext;

    use sui_utils::rand;

    // error enums
    const EUNDEFINED_PROBABILTY_DISTRIBUTION: u64 = 0;
    const EINVALID_ARGUMENTS: u64 = 1;

    const SAMPLE_SIZE: u64 = 12;
    const PRECISION: u64 = 100_000;
    const MAX_LAMBDA: u64 = 18446744073709551615 / 100_000;

    struct ProbabilityDistribution has store, copy, drop {
        distribution: String, // enum: 'uniform', 'normal', 'exponential'
        min: u64,
        max: u64,
        mean: Option<u64>,
        std_dev: Option<u64>,
        lambda: Option<u64>,
        weighted_high: Option<bool>,
    }

    public fun sample_from_distribution(curve: &ProbabilityDistribution, ctx: &mut TxContext): u64 {
        let (min, max) = (curve.min, curve.max);
        let distribution = *string::bytes(&curve.distribution);

        if (distribution == b"uniform") {
            return rand::rng(min, max, ctx)
        } else if (distribution == b"normal") {
            let (mean, std_dev) = (*option::borrow(&curve.mean), *option::borrow(&curve.std_dev));
            return normal(mean, std_dev, min, max, ctx)
        } else if (distribution == b"exponential") {
            let lambda = *option::borrow(&curve.lambda);
            let weighted_high = *option::borrow(&curve.weighted_high);
            return exponential(lambda, min, max, weighted_high, ctx)
        };
            
        abort EUNDEFINED_PROBABILTY_DISTRIBUTION
    }

    // This is an approximation using integer-math. We use 12 samples from a linear distribution
    public fun normal(mean: u64, std_dev: u64, min: u64, max: u64, ctx: &mut TxContext): u64 {
        assert!(max > min, EINVALID_ARGUMENTS);

        let (sum, i) = (0, 0);
        while (i < SAMPLE_SIZE) {
            sum = sum + rand::rng(min, max, ctx);
            i = i + 1;
        };

        // We're careful to avoid over / under flows here
        let avg = sum / SAMPLE_SIZE;
        if (avg > mean) {
            let r = (std_dev as u128) * ((avg - mean) as u128) / ((max - min) as u128);
            let x = (mean as u128) + r;
            if (x > (max as u128)) { return max } else { return max((x as u64), min) }
        } else {
            let r = (std_dev as u128) * ((mean - avg) as u128) / ((max - min) as u128);
            if (r > (mean as u128)) { return min } else { return min(mean - (r as u64), max) }
        }
    }

    public fun exponential(lambda: u64, min: u64, max: u64, weighted_high: bool, ctx: &mut TxContext): u64 {
        assert!(max > min, EINVALID_ARGUMENTS);
        assert!(lambda > 0 && lambda <= MAX_LAMBDA, EINVALID_ARGUMENTS);

        let uniform_value = rand::rng(1, PRECISION, ctx);
        let exp_multiplier = lambda * PRECISION;

        let exp_value = min + (exp_multiplier / uniform_value) % (max - min);
        if (weighted_high) {
            max - (exp_value - min)
        } else {
            min(max(exp_value, min), max)
        }
    }  
}