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
day01 p1               2499     2.064s         826.074us ± 70.079us  (790.878us ... 1.084ms)      810.525us  1.066ms    1.07ms
day01 p2               2474     1.995s         806.674us ± 7.494us   (793.635us ... 845.413us)    811.418us  832.889us  837.828us

day02 p1               7        1.854s         264.934ms ± 762.809us (263.854ms ... 265.99ms)     265.817ms  265.99ms   265.99ms
day02 p2               5        1.754s         350.928ms ± 2.041ms   (348.238ms ... 353.981ms)    351.027ms  353.981ms  353.981ms

day03 p1               20432    2s             97.926us ± 4.666us    (95.551us ... 162.097us)     97.235us   109.968us  142.7us
day03 p2               11837    2.012s         170.053us ± 7.211us   (167.017us ... 298.426us)    169.751us  192.585us  218.114us

day04 p1               441      2.014s         4.567ms ± 201.154us   (4.482ms ... 6.283ms)        4.543ms    5.769ms    5.878ms
day04 p2               43       1.994s         46.376ms ± 44.845us   (46.291ms ... 46.517ms)      46.391ms   46.517ms   46.517ms

day05 p1               1739     1.99s          1.144ms ± 30.006us    (1.131ms ... 1.44ms)         1.143ms    1.303ms    1.366ms
day05 p2               12360    2.001s         161.948us ± 1.646us   (159.702us ... 200.149us)    161.966us  166.696us  168.62us

day06 p1               7144     1.994s         279.207us ± 13.476us  (274.53us ... 572.566us)     278.648us  357.989us  383.607us
day06 p2               2993     1.998s         667.757us ± 5.154us   (653.218us ... 697.431us)    670.019us  684.807us  687.934us

day07 p1               22626    1.995s         88.192us ± 4.399us    (86.464us ... 149.653us)     87.395us   102.764us  131.389us
day07 p2               14532    2.008s         138.2us ± 9.144us     (134.735us ... 314.586us)    137.16us   200.56us   211.06us

day08 p1               5        4.385s         877.012ms ± 3.154ms   (872.492ms ... 879.766ms)    879.352ms  879.766ms  879.766ms
day08 p2               5        4.548s         909.625ms ± 1.713ms   (907.722ms ... 911.907ms)    910.879ms  911.907ms  911.907ms

day09 p1               701      1.985s         2.832ms ± 27.603us    (2.812ms ... 3.086ms)        2.833ms    2.966ms    2.984ms
day09 p2               6        1.972s         328.83ms ± 646.823us  (328.361ms ... 330.106ms)    328.807ms  330.106ms  330.106ms

day10 p1               5        31.561ms       6.312ms ± 1.124ms     (5.543ms ... 8.272ms)        6.156ms    8.272ms    8.272ms
day10 p1 [MEMORY]                              0B ± 0B               (0B ... 0B)                  0B         0B         0B
day10 p2               5        4.857s         971.409ms ± 41.987ms  (938.12ms ... 1.041s)        978.525ms  1.041s     1.041s
day10 p2 [MEMORY]                              4.224MiB ± 949.792KiB (3.603MiB ... 5.869MiB)      3.883MiB   5.869MiB   5.869MiB

day11 p1               1286     2.016s         1.567ms ± 99.036us    (1.498ms ... 2.109ms)        1.554ms    1.948ms    1.985ms
day11 p1 [MEMORY]                              37.547KiB ± 0B        (37.547KiB ... 37.547KiB)    37.547KiB  37.547KiB  37.547KiB
day11 p2               305      2.023s         6.635ms ± 289.65us    (6.458ms ... 8.749ms)        6.634ms    8.226ms    8.527ms
day11 p2 [MEMORY]                              175.070KiB ± 0B       (175.070KiB ... 175.070KiB)  175.070KiB 175.070KiB 175.070KiB

day12 p1               4289     2.03s          473.371us ± 37.275us  (456.004us ... 620.565us)    465.793us  597.723us  599.776us
```

## Compatibility

Tested on `0.15.2`.
