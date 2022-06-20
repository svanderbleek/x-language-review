# Features

I expect Nim to perform well on evaluation based on the quality of the [language manual](https://nim-lang.org/docs/manual.html), [test cases](https://github.com/nim-lal/tsts), and awareness of software verification shown with advanced ideas like [DrNim](https://nim-lang.org/docs/drnim.html).
There is no formal model of Nim, but there aren't formal models of most languages except those that come from academia.

I'm not a member of the Nim language community but I joined their [chat](https://nim-lang.org/community.html) and ran this article by them to ensure fairness. The community was great and offered me generous advice and support. Anyway let's get started!

## Security and Memory Safety

In the [FAQ](https://nim-lang.org/faq.html) there's a section about Nim's memory safety.

> Nim provides memory safety by not performing pointer arithmetic, with optional checks, traced and untraced references and optional non-nullable types.

Let's begin by looking at traced references and variables.

```nim
type
  T = ref object
    x: int

proc p(t : T) =
  echo t.x

var t : T
p(t)
```

This simple example compiles and produces a segfult when executed.
Why is that? It appears to have given `t` the value `nil` which we can verify with introspection using `t.repr`.
My expectation would be for the compiler to catch use of `t.x` given `p(t)` is called with a `nil` reference.

We can see `t` is `nil` by using [inim](https://github.com/inim-repl/INim) for an interactive session.

```nim
nim> var t : T
nim> t.repr
nil == type string
```

It's a little confusing why this is happening, except that Nim must consider nil to be the default value for a reference.
Nim says the following about [variables](https://nim-lang.org/docs/manual.html#statements-and-expressions-var-statement)

> Var statements declare new local and global variables and initialize them.

and

> If an initializer is given, the type can be omitted: the variable is then of the same type as the initializing expression. Variables are always initialized with a default value if there is no initializing expression. The default value depends on the type and is always a zero in binary. 


Removing the `ref` keyword makes `T` a default object instead of `nil`, and things work nicely.

```nim
nim> var t : T
nim> t.x
0 == type int
```

This is similar to [zero values](https://go.dev/tour/basics/12) in Go.

Is it fair to expect Nim to catch this error in compile time? We see the [definition](https://nim-lang.org/docs/manual.html#definitions) of runtime errors and relation to safe language features

> An unchecked runtime error is an error that is not guaranteed to be detected and can cause the subsequent behavior of the computation to be arbitrary. Unchecked runtime errors cannot occur if only safe language features are used and if no runtime checks are disabled.

So the question becomes is `ref` a safe language feature? The manual says about references and pointers that

> Nim distinguishes between traced and untraced references. Untraced references are also called pointers. Traced references point to objects of a garbage-collected heap, untraced references point to manually allocated objects or objects somewhere else in memory. Thus untraced references are unsafe.

and

> Traced references are declared with the ref keyword, untraced references are declared with the ptr keyword. 

So we are using the `ref` keyword and thus a traced reference which should be safe. For this example is it is not.

Let's compare with Rust to show that a we can catch an error like this. The Rust compiler disallows uninitialized variables, meaning any use of `t` would be caught. And there is no concept of a `nil` value so the default to `nil` scenario could not happen.

Actually Nim itself shows it can catch this error by using an experimental feature [strictNotNil](https://nim-lang.org/docs/manual_experimental.html#strict-not-nil-checking).
For our example `nim c --experimental:strictNotNil ref.nim` works nicely to warn at compile time with

> ref.nim(6, 8) Warning: can't deref t, it might be nil param with nilable type on line 5:7 [StrictNotNil]

Let's look at an explicit claim to memory safety Nim makes in describing the [var return type](https://nim-lang.org/docs/manual.html#procedures-var-return-type) feature.

> Memory safety for returning by var T is ensured by a simple borrowing rule: If result does not refer to a location pointing to the heap (that is in result = X the X involves a ptr or ref access) then it has to be derived from the routine's first parameter:

```nim
proc forward[T](x: var T): var T =
  result = x # ok, derived from the first parameter.

proc p(param: var int): var int =
  var x: int
  # we know 'forward' provides a view into the location derived from
  # its first argument 'x'.
  result = forward(x) # Error: location is derived from `x`
                      # which is not p's first parameter and lives
                      # on the stack.
```

Running the example through the compiler we get the helpful error message

> var_return_type.nim(8, 19) Error: 'x' escapes its stack frame; context: 'forward(x)'; see https://nim-lang.github.io/Nim/var_t_return.html

For [arrays](https://nim-lang.org/docs/manual.html#types-array-and-sequence-types) we have a combination of compile and runtime boundschecking.

> Arrays are always bounds checked (statically or at runtime).

So that

```nim
var a : array[0..1, int]

echo a[2]
```

gives

> array_compile.nim(3, 6) Error: index 2 not in 0 .. 1

at compile and

```nim
var
  a : array[0..1, int]
  i = 2

echo a[i]
```

gives

> Error: unhandled exception: index 2 not in 0 .. 1 [IndexDefect]

after running the executable. However if we build `drnim` we can leverage z3 to check the index at compile time getting

```
Warning: cannot prove: 0 <= i; cannot map to Z3: range 0..1(int) [IndexCheck]
Warning: cannot prove: i <= 1; cannot map to Z3: range 0..1(int) [IndexCheck]
Warning: cannot prove: i <= 1; counter example: i -> 2 [IndexCheck]
```

which is pretty cool.
