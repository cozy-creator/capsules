module sui_utils::string2 {
    use std::string::{Self, String};
    use std::vector;

    public fun empty(): String {
        string::utf8(vector::empty())
    }
}