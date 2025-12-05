# Advent of code 2025 in Zig

## Run

```shell
zig build <dayX>
# zig build day01
```

## Run with docker

```shell
zig() {
  docker run --ulimit=host --rm -it -v $(pwd):/work -w /work ghcr.io/darkness4/aoc-2025:base "$@"
}
zig build <dayX>
```

## Benchmark results

```shell
benchmark              runs     total time     time/run (avg ± σ)    (min ... max)                p75        p99        p995
-----------------------------------------------------------------------------------------------------------------------------
day01 p1               2475     1.996s         806.531us ± 7.191us   (792.763us ... 842.978us)    811.529us  830.604us  834.852us
day01 p2               2474     1.995s         806.674us ± 7.494us   (793.635us ... 845.413us)    811.418us  832.889us  837.828us
day02 p1               7        1.854s         264.934ms ± 762.809us (263.854ms ... 265.99ms)     265.817ms  265.99ms   265.99ms
day02 p2               5        1.754s         350.928ms ± 2.041ms   (348.238ms ... 353.981ms)    351.027ms  353.981ms  353.981ms
day03 p1               20432    2s             97.926us ± 4.666us    (95.551us ... 162.097us)     97.235us   109.968us  142.7us
day03 p2               11837    2.012s         170.053us ± 7.211us   (167.017us ... 298.426us)    169.751us  192.585us  218.114us
day04 p1               439      1.996s         4.548ms ± 94.505us    (4.36ms ... 6.014ms)         4.576ms    4.732ms    4.893ms
day04 p2               12       1.876s         156.372ms ± 488.133us (156.104ms ... 157.887ms)    156.384ms  157.887ms  157.887ms
```

## Compatibility

Tested on `0.15.2`.
