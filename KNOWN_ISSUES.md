# Known issues

The examples were written for an earlier design of the language and ported to
the language as documented at
[stenopos.github.io](https://stenopos.github.io/language/). This file lists
what is still missing. `scripts/check.sh` reads the machine-readable list in
`scripts/quarantine.txt`; remove an entry there, and here, once its example
works.

Errors below are from Stenopos 1.0.0-rc.5.

## Quarantined: 1.0 features not implemented yet

Each of these is kept in its intended 1.0 form.

| Example | Needs | Error today |
|---------|-------|-------------|
| `basics/factorial.sten` | `const func`, evaluated at compile time | `a top-level 'const' needs a scalar or str type` |
| `data/tuples.sten` | tuple types, tuple returns and destructuring | `expected a statement, found ','` |
| `error_handling/with_block.sten` | `with (File f = open(path)) { ... }` | `undefined variable 'f'` |
| `errors/use_after_move.sten` | moves (ADR-0040): `str b = a` makes `a` unusable | compiles, because every transfer still copies |
| `advanced/ffi.sten` | `extern "C"` functions with pointer, `str`, struct and callback types (only all-`int32` or all-`int64` signatures work) | `undefined variable 'ptr'` |
| `advanced/unsafe.sten` | heap allocation through raw pointers (`std.mem`), pointer arithmetic, `ptr[void]`, `unsafe_cast` | `cannot find module 'std.mem'` |
| `advanced/type_aliases.sten` | `type Name = T`, generic aliases | `undefined variable 'type'` |
| `advanced/modules.sten` | `import a.b.name`, `import a.b`, `import ... as`, `pub import`, `protected` | `cannot find module 'project.utils.helpers'` |
| `showcase/ml_pipeline.sten` | FFI with pointer and `float64` arguments (BLAS), pointer arithmetic, `spawn { ... }`, `chan[Struct]`, `if (c) a else b` | `expected ',' or a newline after a struct field` |

## Quarantined: hardware, an OS, or a program that never exits

| Example | Why | Checked as |
|---------|-----|------------|
| `showcase/kernel_module.sten` | A Linux kernel module: needs freestanding kernel-ABI code generation, Kbuild, and the `kernel` bindings in std (still "designed"; they do not compile) | skipped: `undefined variable 'str'` (in std's `kernel.printk`) |
| `showcase/bare_metal.sten` | A Raspberry Pi 3/4 kernel: needs a freestanding `aarch64-none-elf` target, constant expressions in top-level `const`, MMIO through raw pointers | skipped: `a top-level 'const' must be initialized with a literal constant` |
| `showcase/web_server.sten` | An HTTP server on port 8080 that runs until stopped | built only |

## Quarantined: compiler bugs

None. The compiler bugs below, found while porting, are all fixed in the
Syntagma commit `syntagma.lock` pins (each notes where).

### 1. Methods on a generic struct do not exist

*Fixed in Syntagma 8587c7f.*

```stenopos
struct Box[T] {
    T value

    func get() -> T {
        return this.value
    }
}

func main() -> int32 {
    Box[int32] b = Box { value: 7 }
    println("{b.get()}")
    return 0
}
```

`error[E0300]: struct 'Box__g0' has no method 'get'` — the method is accepted
at its declaration but dropped from the instantiation (and the message shows
the mangled name). Blocks `advanced/generics.sten` (`Stack[T]`).

### 2. A generic function returning `Pair[B, A]` emits invalid IR

*Fixed in Syntagma 6ae527d.*

```stenopos
struct Pair[A, B] {
    A first
    B second
}

func swap[A, B](Pair[A, B] p) -> Pair[B, A] {
    return Pair { first: p.second, second: p.first }
}

func main() -> int32 {
    Pair[str, int32] p = Pair { first: "age", second: 30 }
    Pair[int32, str] q = swap(p)
    println("{q.first} {q.second}")
    return 0
}
```

`llc: error: use of undefined value '@swap__g0_0'`. Blocks
`advanced/generics.sten`.

### 3. `?.` through nullable struct fields

*Fixed in Syntagma 8587c7f, fa98f14.*

```stenopos
struct Employee {
    str? email
}

struct Department {
    Employee? lead
}

struct Company {
    Department? engineering
}

func main() -> int32 {
    Company co = Company { engineering: null }
    str? e = co.engineering?.lead?.email
    println(e ?? "unknown")
    return 0
}
```

The compiler itself aborts: `stenopos: array index out of bounds: index 6000,
length 3`. A single step onto a nullable field is wrong too:

```stenopos
struct Employee {
    str name
    str? email
}

func main() -> int32 {
    str? mail = "bob@acme.com"
    Employee? e = Employee { name: "Bob", email: mail }
    str? m = e?.email
    println(m ?? "none")
    return 0
}
```

`llc: error: '%37' defined with type '{ i1, { i1, { i64, ptr } } }' but
expected '{ i64, ptr }'` — `?.` wraps an already-nullable field in a second
nullable instead of flattening it. Blocks `advanced/nullable.sten`.

## Compiler bugs worked around in passing examples

### 4. Assigning a captured variable inside a lambda is silently lost

*Fixed in Syntagma 1325824: an error now.*

```stenopos
func main() -> int32 {
    int32 count = 0
    fn()->int32 f = || -> int32 {
        count += 1
        return count
    }
    println("{f()} {f()} {count}")
    return 0
}
```

Prints `0 0 0`. With by-copy captures the result should be `1 1 0` (or `1 2 0`
if the environment persisted), or the assignment should be rejected. The
original `make_counter` demo in `advanced/closures.sten` depended on this, so
the example now demonstrates by-copy capture instead.

### 5. `List[str].join(sep)` ignores its argument

*Fixed in Syntagma 1325824: an error now.*

```stenopos
func main() -> int32 {
    List[str] b = list_new()
    b.push("1")
    b.push("2")
    println(b.join(", "))
    return 0
}
```

Prints `12`: the built-in `join()` takes no separator, but a separator is
accepted and dropped instead of being an error. The examples use
`std.string.join(list, sep)`.

### 6. Interpolating a `List` emits invalid IR

*Fixed in Syntagma 1325824: an error now.*

```stenopos
func main() -> int32 {
    List[int32] xs = [1, 2, 3]
    println("{xs}")
    return 0
}
```

`llc: error: '%5' defined with type '{ i64, i64, i64, ptr }' but expected
'i32'`. It should be a type error (or format the list).

### 7. Parallel builds race on fixed temporary files

*Fixed in Syntagma f9baa7b.*

Module resolution writes and runs `/tmp/stenresolve.<n>.sh` and reads
`/tmp/stenresolve.<n>.txt`, where `<n>` is a counter, not a unique name. Two
`stenopos build` processes at once overwrite each other's files, and imports
fail at random (`cannot find module 'std.fmt'`). It is also unsafe on a shared
machine: another user can plant the script. `scripts/check.sh` therefore
builds one example at a time.

### 8. Diagnostics lose the file name once std is imported

*Fixed in Syntagma 6ae527d.*

```stenopos
import std.string.{trim}

func main() -> int32 {
    int32 x = true
    return 0
}
```

The error points at `--> line 285` (a line in the merged source) instead of
`file.sten:4:11`.

### 9. Smaller diagnostic problems

*Fixed in Syntagma 6ae527d.*

- A `return true` in a function declared `-> int32` reports only `return type
  mismatch`, with no error code and no location (`errors/type_mismatch.sten`).
- `cast[int32](flag)` on a `bool` reports `the initializer of 'n' is not int32
  (no implicit conversions — use cast[int32]())`, suggesting the very cast that
  was written; it should say that `bool` is not a numeric type.
- `@tainted str input = arg(1)` is shown in the taint-tracking guide but
  rejected: `'@tainted' cannot be applied to a statement`. Either the guide or
  the compiler is wrong; `security/taint_tracking.sten` marks the source
  function instead.
- `stenopos fmt` moves a multi-statement `case` body to the indentation of the
  `case` itself, unlike the style in the control-flow guide (the body indented
  under its `case`); `advanced/pattern_matching.sten`, `data/enums.sten` and
  `showcase/cli_app.sten` keep the guide's style.

## Library gaps

- `std.net`'s functions carry no effect annotation, so an `@net` function
  cannot call them ("whose effects are unverified").
  `security/effects.sten` calls the `tcp_connect`/`tcp_close` built-ins
  directly.
- `read_file` on a missing file returns `""` instead of throwing, so
  `error_handling/try_catch_finally.sten` and `showcase/cli_app.sten` treat an
  empty result as the error.

## Ported with a documented substitute

These examples run, but part of the original design is not in the language
yet; each file says so in its header comment.

| Example | Original | Now |
|---------|----------|-----|
| `data/classes.sten` | `abstract class` / `abstract func` | a `virtual` method with a default body |
| `data/strings.sten` | `s.contains(...)`, `s.replace(...)` methods | `std.string` functions; replace as `join(split(...))` |
| `data/arrays.sten` | `int64 numbers[5]` | `int64[5] numbers` |
| `error_handling/try_catch_finally.sten` | typed `catch (IoError e)` arms, `e.message()` | one `catch (Error e)`, the kind in the message |
| `concurrency/*.sten` | `Flight` join handles, module-level shared locks, `ch.close()`, `for (v in ch)`, `chan[int32](4)`, `semaphore[3]` | shared values passed to `spawn`, a semaphore or channel as the join, a known item count, `semaphore(3)` |
| `security/constant_time.sten` | `secret[str]`, a library `ct_eq` | a `secret[uint32]` hash and an XOR comparison |
| `security/crypto.sten` | `@sensitive` struct fields, `uint8[]`, `secure_zero` | `@sensitive` locals over `List[int32]` byte buffers, an in-place wipe |
| `security/effects.sten` | `@filesystem`, `@network` | `@io`/`@net` with `@cap(File)`/`@cap(Network)` |
| `security/capabilities.sten` | `std.caps`, `cap.grant[FileReadCap]()` | the built-in `cap[File]` and `grant[File]()` |
| `advanced/annotations.sten` | `@no_discard`, `@packed`, `@aligned`, `@opaque`, `uint8`/`uint16` | must-use by default with `@ignore_discard`; the layout annotations shown in comments |
| `advanced/pattern_matching.sten` | `match` as an expression, guards, struct destructuring, `case 'a', 'e'`, generic `Result[T]` | `match` statements, if/else for conditions, one pattern per case, a concrete payload enum |
| `advanced/string_interpolation.sten` | `{x:x}`, `{pi:.2}`, `if` expressions, `{{` escapes | `std.fmt`, `std.math.round`, helper functions, `\{` |
| `advanced/structs.sten` | `static func`, `const` fields, `uint8` | constructor functions, plain fields, `int32` |
| `advanced/traits.sten` | static trait methods, trait inheritance, `Drawable[]` | not shown |
| `showcase/cli_app.sten` | `JsonFormatter{}.format(lines)` through the trait | a `match` that picks the concrete formatter |
