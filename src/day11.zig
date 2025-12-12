const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day11.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day11_test.txt"), "\n");
const input2_test = std.mem.trimRight(u8, @embedFile("day11p2_test.txt"), "\n");

fn h(data: []const u8) u64 {
    return std.hash.Wyhash.hash(0, data);
}

const CacheKey = struct {
    here: u64,
    dst: u64,
};

fn dfs(cache: *std.AutoHashMap(CacheKey, usize), graph: std.AutoHashMap(u64, []u64), here: u64, comptime dst: u64) !usize {
    if (here == dst) return 1;
    if (cache.get(.{ .here = here, .dst = dst })) |count| return count;

    var count: usize = 0;
    if (graph.get(here)) |children| {
        for (children) |child| {
            count += try dfs(cache, graph, child, dst);
        }
    }

    try cache.put(.{ .here = here, .dst = dst }, count);

    return count;
}

fn day11(allocator: std.mem.Allocator, data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var values_buffer: [613][30]usize = undefined;
    var values_size: [613]usize = [_]usize{0} ** 613;

    // Parent -> children
    var graph = std.AutoHashMap(u64, []u64).init(allocator);
    defer graph.deinit();

    var cache = std.AutoHashMap(CacheKey, usize).init(allocator);
    defer cache.deinit();

    var line_idx: usize = 0;
    while (lines.next()) |line| : (line_idx += 1) {
        var scan_idx: usize = 0;

        // Scan left
        const key_start_idx: usize = scan_idx;
        while (line[scan_idx] != ':') {
            scan_idx += 1;
        }
        const key = h(line[key_start_idx..scan_idx]);
        scan_idx += 1; // Skip ':'
        scan_idx += 1; // Skip space

        var value_idx: usize = 0;
        while (scan_idx < line.len) : (value_idx += 1) {
            const value_start_idx: usize = scan_idx;
            while (line[scan_idx] != ' ') {
                scan_idx += 1;
                if (scan_idx >= line.len) break;
            }
            const value = h(line[value_start_idx..scan_idx]);
            scan_idx += 1; // Skip space

            values_buffer[line_idx][value_idx] = value;
            values_size[line_idx] += 1;
        }

        try graph.put(key, values_buffer[line_idx][0..values_size[line_idx]]);
    }

    return try dfs(&cache, graph, comptime h("you"), comptime h("out"));
}

fn day11p2(allocator: std.mem.Allocator, data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var values_buffer: [613][30]usize = undefined;
    var values_size: [613]usize = [_]usize{0} ** 613;

    // Parent -> children
    var graph = std.AutoHashMap(u64, []u64).init(allocator);
    defer graph.deinit();

    var cache = std.AutoHashMap(CacheKey, usize).init(allocator);
    defer cache.deinit();

    var line_idx: usize = 0;
    while (lines.next()) |line| : (line_idx += 1) {
        var scan_idx: usize = 0;

        // Scan left
        const key_start_idx: usize = scan_idx;
        while (line[scan_idx] != ':') {
            scan_idx += 1;
        }
        const key = h(line[key_start_idx..scan_idx]);
        scan_idx += 1; // Skip ':'
        scan_idx += 1; // Skip space

        var value_idx: usize = 0;
        while (scan_idx < line.len) : (value_idx += 1) {
            const value_start_idx: usize = scan_idx;
            while (line[scan_idx] != ' ') {
                scan_idx += 1;
                if (scan_idx >= line.len) break;
            }
            const value = h(line[value_start_idx..scan_idx]);
            scan_idx += 1; // Skip space

            values_buffer[line_idx][value_idx] = value;
            values_size[line_idx] += 1;
        }

        try graph.put(key, values_buffer[line_idx][0..values_size[line_idx]]);
    }

    // TThe number of paths from a to b to c is equal to the number of paths from a to b multiplied by the number of paths from b to c.
    return try dfs(&cache, graph, comptime h("svr"), comptime h("dac")) *
        try dfs(&cache, graph, comptime h("dac"), comptime h("fft")) *
        try dfs(&cache, graph, comptime h("fft"), comptime h("out")) +
        try dfs(&cache, graph, comptime h("svr"), comptime h("fft")) *
            try dfs(&cache, graph, comptime h("fft"), comptime h("dac")) *
            try dfs(&cache, graph, comptime h("dac"), comptime h("out"));
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day11(std.heap.page_allocator, input);
    const p1_time = timer.lap();
    const result_p2 = try day11p2(std.heap.page_allocator, input);
    const p2_time = timer.read();
    std.debug.print("day11 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day11 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{});
    defer bench.deinit();
    try bench.add("day11 p1", struct {
        pub fn call(allocator: std.mem.Allocator) void {
            _ = day11(allocator, input) catch unreachable;
        }
    }.call, .{});
    try bench.add("day11 p2", struct {
        pub fn call(allocator: std.mem.Allocator) void {
            _ = day11p2(allocator, input) catch unreachable;
        }
    }.call, .{});
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    try bench.run(stdout);
    try stdout.flush();
}

test "day11" {
    const result = try day11(std.heap.page_allocator, input_test);
    const expect = 5;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

test "day11p2" {
    const result = try day11p2(std.heap.page_allocator, input2_test);
    const expect = 2;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}
