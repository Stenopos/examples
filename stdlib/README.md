# Standard-library examples

Short, runnable demos of the batteries in Stenopos's standard library.

| File | Module(s) | Shows |
|------|-----------|-------|
| [`sorting.sten`](sorting.sten) | `std.sort` | value-semantic sort (returns a new list), binary search |
| [`hashing.sten`](hashing.sten) | `std.hash` | FNV-1a, CRC-32, djb2 non-cryptographic hashes |
| [`encoding.sten`](encoding.sten) | `std.hex`, `std.base64` | encode/decode byte buffers, round-trips |
| [`formatting.sten`](formatting.sten) | `std.fmt` | radix, padding, thousands separators |
| [`random_demo.sten`](random_demo.sten) | `std.random` | seeded, reproducible PRNG |

Run one with the installed toolchain:

```bash
stenopos run sorting.sten
```

## Proving a program is leak-free — the memory ledger

Any Stenopos binary can report whether its heap balanced, with no valgrind needed
(works on release builds and other architectures too). Set `STENOPOS_MEMLOG`:

```bash
STENOPOS_MEMLOG=1 stenopos run sorting.sten
# ... program output ...
# MEMLOG: allocs=93 frees=93 live=0 alloc_bytes=1740 — CLEAN (all matched)
```

`live=0` means every allocation was freed. Use `STENOPOS_MEMLOG=2` to also log each
`ALLOCATED <ptr> <size>` / `DEALLOCATED <ptr>` event for per-pointer matching.

> These demos `import std.*`; they run against a toolchain whose bundled standard
> library includes these modules.
