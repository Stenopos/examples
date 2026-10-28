# examples

Example programs written in [Stenopos](https://stenopos.github.io), a
memory-safe, taint-aware systems programming language.

This repository is developed on the Stenopos Gitea server; the GitHub copy is
published automatically after every build and test passes.

## Running examples

Install Stenopos, then:

```bash
stenopos run basics/hello.sten
stenopos run college/fibonacci.sten
stenopos run concurrency/channels.sten
```

## Checking every example

```bash
STENOPOS=/path/to/stenopos sh scripts/check.sh            # all examples
STENOPOS=/path/to/stenopos sh scripts/check.sh basics/math.sten
```

For each `<name>.sten` the script compares the program's output with
`<name>.expected` and its exit code with `<name>.exitcode` (default 0); a
`<name>.args` file holds command-line arguments, and the program runs from its
own directory. Programs under `errors/` and `verified/compile-fail/` must be
*rejected* by the compiler, with a diagnostic containing the text of their
`.expected` file. CI runs the script on every push.

A few examples need a part of the 1.0 language that is not implemented yet,
hit a known compiler bug, or need hardware; they are listed in
[`scripts/quarantine.txt`](scripts/quarantine.txt) and explained in
[`KNOWN_ISSUES.md`](KNOWN_ISSUES.md). Each one is kept, written as it will
work.

## Directory Structure

| Directory | Description |
|-----------|-------------|
| `basics/` | Hello world, types, constants, math, functions, checked overflow |
| `control_flow/` | If/else, loops, match/case, break/continue |
| `data/` | Arrays, strings, tuples, enums, structs, classes |
| `ownership/` | Value semantics, deep copies, borrowing parameters, discard |
| `casting/` | Explicit numeric conversions with `cast[T]` |
| `concurrency/` | Hemerodromes (green threads), channels, atomics, mutex, rwlock, spinlock, semaphore |
| `error_handling/` | try/catch/finally, with blocks, defer |
| `security/` | Taint tracking, effects, capabilities, constant-time secrets, sensitive data |
| `advanced/` | Unsafe, FFI, generics, traits, closures, modules, annotations, contracts, nullable, pattern matching |
| `algorithms/` | BFS, Dijkstra, histograms, matrices, statistics over nested collections |
| `college/` | Classic computer-science exercises |
| `stdlib/` | Short demos of the standard library |
| `showcase/` | Web server, CLI app, toy OS, Linux kernel module, Raspberry Pi bare-metal OS, ML pipeline |
| `errors/` | Intentional compile failures showing what the compiler catches |
| `verified/` | The original release-verification suite, including `compile-fail/` |

## License

Dual-licensed under MIT and Apache 2.0.

*Ἀσφάλεια περὶ πλείστου: security above all.*
