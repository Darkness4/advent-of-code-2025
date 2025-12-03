const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day03.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day03_test.txt"), "\n");

fn day03(data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');
    var acc: usize = 0;

    while (lines.next()) |line| {
        var max: u8 = 0;
        var max_idx: usize = 0;
        // The idea is to build the biggest 2 digits number.
        // Skip the last digit because if it is chosen as the max, we won't be
        // a able to build a TWO digits number.
        for (0.., line[0 .. line.len - 1]) |i, c| {
            if (max < c) {
                max = c;
                max_idx = i;
            }
            if (max == '9') break;
        }
        // Find the last digit to build our two digits number.
        // Look at the right side of the max digit.
        var max2: u8 = 0;
        for (line[max_idx + 1 .. line.len]) |c| {
            if (max2 < c) {
                max2 = c;
            }
            if (max2 == '9') break;
        }
        acc += (max - '0') * 10;
        acc += max2 - '0';
    }

    return acc;
}

fn day03p2(data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');
    var acc: usize = 0;

    while (lines.next()) |line| {
        var max_idx: usize = 0;
        var res: usize = 0;
        // The idea is to build the biggest 12 digits number.
        var skip: usize = 12;
        while (skip > 0) {
            skip -= 1;
            var max: u8 = 0;
            for (max_idx.., line[max_idx .. line.len - skip]) |i, c| {
                if (max < c) {
                    max = c;
                    max_idx = i + 1;
                }
                if (max == '9') break;
            }
            res = (res * 10) + (max - '0');
        }
        // std.debug.print("res: {d}\n", .{res});
        acc += res;
    }

    return acc;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day03(input);
    const p1_time = timer.lap();
    const result_p2 = try day03p2(input);
    const p2_time = timer.read();
    std.debug.print("day03 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day03 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{});
    defer bench.deinit();
    try bench.add("day03 p1", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day03(input) catch unreachable;
        }
    }.call, .{});
    try bench.add("day03 p2", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day03p2(input) catch unreachable;
        }
    }.call, .{});
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    try bench.run(stdout);
    try stdout.flush();
}

test "day03" {
    const result = try day03(input_test);
    const expect = 357;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

test "day03p2" {
    const result = try day03p2(input_test);
    const expect = 3121910778619;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}
