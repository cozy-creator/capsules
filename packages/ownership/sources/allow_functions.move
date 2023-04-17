// This tuple is the module-address where the functions are located, and the ACL (access control list)
// of which functions are allowed to be called. It's up to the modules themselves to number and gate
// their own functions.
// For example, if 0x123::my_module assigns '3' to a function, then on the ACL[3] (the 4th bit) must
// be flipped to 1 (true) for this function-call to be allowed through.

module ownership::allowed_functions {


}