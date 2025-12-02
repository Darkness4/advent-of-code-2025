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
day02 p1               7        2.023s         289.065ms ± 11.318ms  (274.494ms ... 309.956ms)    293.354ms  309.956ms  309.956ms
day02 p2               4        1.852s         463.122ms ± 5.695ms   (455.49ms ... 469.113ms)     469.113ms  469.113ms  469.113ms
```

## Compatibility

Tested on `0.15.2`.
