# Features

## Security and Memory Safety

> Nim provides memory safety by not performing pointer arithmetic, with optional checks, traced and untraced references and optional non-nullable types.

```nim
type
  T = ref object

var t : T

echo t
```

This simple example compiles and produces a segfult when executed. Removing the `ref` keyword makes `T` a default object similar to the approach of Go. My expectation here is for the compiler to catch use of `t`.

The [Language Manual](https://nim-lang.org/docs/manual.html) says

> An unchecked runtime error is an error that is not guaranteed to be detected and can cause the subsequent behavior of the computation to be arbitrary. Unchecked runtime errors cannot occur if only safe language features are used and if no runtime checks are disabled.

So the question becomes is `ref` a "safe language" feature? The manual says about references and pointers that

> Nim distinguishes between traced and untraced references. Untraced references are also called pointers. Traced references point to objects of a garbage-collected heap, untraced references point to manually allocated objects or objects somewhere else in memory. Thus untraced references are unsafe.

and

> Traced references are declared with the ref keyword, untraced references are declared with the ptr keyword. 

The example uses the `ref` keyword and is thus a traced reference which should be safe. It appears it is currently not.

Let's compare with Rust, which won't let this happen at all. The compiler disallows uninitialized variables, meaning any use of `t` would be caught.
