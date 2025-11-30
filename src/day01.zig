const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day01.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day01_test.txt"), "\n");

fn day01(_: []const u8) !usize {
    return 0;
}

fn day01p2(_: []const u8) !usize {
    return 0;
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
    const expect = 0;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

test "day01p2" {
    const result = try day01p2(input_test);
    const expect = 0;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}
