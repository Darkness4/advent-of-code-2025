const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day01.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day01_test.txt"), "\n");

/// scanNumber scans a number in a string. Much more efficient than std.fmt.parseInt
/// since we ignore '-' and other characters that could define a number (like hex, etc...).
/// A very naive implementation, yet the fastest for Advent of Code.
fn scanNumber(comptime T: type, data: []const u8, idx: *usize) ?T {
    var number: ?T = null;
    if (idx.* >= data.len) return number;
    var char = data[idx.*];
    while (char >= '0' and char <= '9') {
        const v = char - '0';
        number = if (number) |n| n * 10 + (char - '0') else v;
        idx.* += 1;
        if (idx.* >= data.len) break;
        char = data[idx.*];
    }
    return number;
}

fn day01(data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');
    var acc: usize = 0;
    var counter: i64 = 50;
    while (lines.next()) |line| {
        var neg: i64 = 1;
        if (line[0] == 'L') {
            neg = -1;
        }
        var ch_idx: usize = 1;
        const number = scanNumber(i64, line, &ch_idx) orelse unreachable;
        counter += number * neg;
        if (@mod(counter, 100) == 0) {
            acc += 1;
        }
    }

    return acc;
}

fn day01p2(data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');
    var acc: usize = 0;
    var counter: i64 = 50;
    var dir: u8 = 'R';
    while (lines.next()) |line| {
        if (line[0] != dir) {
            // Reverse direction relatively to last direction.
            // This is because @divFloor behave differently for negative numbers,
            // so we work with only positive numbers. (For example: 0.01 is 0, but -0.01 is -1.)
            dir = line[0];
            counter = @mod(100 - counter, 100);
        }
        var ch_idx: usize = 1;
        counter += scanNumber(i64, line, &ch_idx) orelse unreachable;
        acc += @abs(@divFloor(counter, 100));
        counter = @mod(counter, 100);
    }
    return acc;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day01(input);
    const p1_time = timer.lap();
    const result_p2 = try day01p2(input);
    const p2_time = timer.read();
    std.debug.print("day01 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day01 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{});
    defer bench.deinit();
    try bench.add("day01 p1", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day01(input) catch unreachable;
        }
    }.call, .{});
    try bench.add("day01 p2", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day01p2(input) catch unreachable;
        }
    }.call, .{});
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    try bench.run(stdout);
    try stdout.flush();
}

test "day01" {
    const result = try day01(input_test);
    const expect = 3;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

test "day01p2" {
    const result = try day01p2(input_test);
    const expect = 6;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

test "day01p2.2" {
    const result = try day01p2("R1000");
    const expect = 10;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

test "day01p2.3" {
    const result = try day01p2("R1050");
    const expect = 11;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

test "day01p2.4" {
    const result = try day01p2("R50\nR0\nR0\nR100");
    const expect = 2;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

test "day01p2.5" {
    const result = try day01p2("L50\nL0\nL0\nL100");
    const expect = 2;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}
