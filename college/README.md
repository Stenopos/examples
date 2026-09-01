# College examples

Classic computer-science programs — the kind you meet in a first or second
programming course — written in Stenopos. Each is self-contained and runs on the
shipped toolchain.

| File | Concept |
|------|---------|
| [`fibonacci.sten`](fibonacci.sten) | iteration, recursion, and memoization (with `int64` for the big terms) |
| [`sieve.sten`](sieve.sten) | Sieve of Eratosthenes over a `List[bool]` |
| [`quicksort.sten`](quicksort.sten) | in-place quicksort (Lomuto partition, recursion) |
| [`towers_of_hanoi.sten`](towers_of_hanoi.sten) | the classic recursion exercise |
| [`linked_list.sten`](linked_list.sten) | a singly linked list via an index arena (no raw pointers needed) |
| [`hash_map.sten`](hash_map.sten) | a hash map by hand — open addressing with linear probing |

```bash
stenopos run fibonacci.sten
```

A note on style: Stenopos collections are value types, so these examples either
return new data or pass a `List` directly to a helper that updates it in place
(`.set()`/`.get()`), rather than mutating a collection wrapped inside a struct.
