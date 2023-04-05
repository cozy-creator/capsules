Unfortunately Sui does not yet support programmable transactions that can pass references, and does not support script transactions yet. This means that, if you have two functions you want to compose together by passing references, like this:

`fun_a() -> &mut Object -> fun_b()`

You will need to manually write and deploy Move code to do this; the client cannot dynamically compose this reference-passing behavior. HOWEVER anyone can write and deploy a program which calls function-A, takes its references, and supplies it as input to function-B.

And that's what this folder is for! A stop-gap measure until Sui has a better solution.

To make this easier, we plan to create templates, which allow you to compose functions A and B in commonly used patterns.
