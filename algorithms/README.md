# Algorithm examples

Real-world programs that exercise Stenopos across nested collections, `int64`
arithmetic beyond 2³¹, structs/enums, and recursion.

| File | What it shows |
|------|---------------|
| [`bfs.sten`](bfs.sten) | breadth-first search over a `List[List[int32]]` adjacency graph with a list-as-queue |
| [`dijkstra.sten`](dijkstra.sten) | shortest paths with `List[int64]` distances (weights exceed 2³¹) |
| [`histogram.sten`](histogram.sten) | bucketing `int64` measurements into a `HashMap[int32, int64]` |
| [`matrix.sten`](matrix.sten) | `int64` matrix multiply over `List[List[int64]]`, plus the trace |
| [`stats.sten`](stats.sten) | descriptive statistics (sum/min/max/mean/median) over a `List[int64]` including negatives |

Run one with the installed toolchain:

```bash
stenopos run bfs.sten
```

Every program here compiles, runs, and is valgrind-clean on the Stenopos
self-hosted compiler (the shipped toolchain), and each was written during the
compiler's own dogfooding — several surfaced and fixed real `int64`-in-collections
bugs along the way.
