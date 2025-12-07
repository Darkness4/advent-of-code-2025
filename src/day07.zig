const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day07.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day07_test.txt"), "\n");

fn day07(data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');
    var acc: usize = 0;

    var lasers = [_]u8{0} ** 141;

    const first = lines.next() orelse unreachable;
    for (0.., first) |i, c| {
        if (c == 'S') {
            lasers[i] = '|';
            break;
        }
    }

    while (lines.next()) |line| {
        for (0.., line) |i, c| {
            // If there is a laser above us
            if (c == '^' and lasers[i] == '|') {
                acc += 1;
                lasers[i - 1] = '|';
                lasers[i + 1] = '|';
                lasers[i] = 0;
            }
        }
    }

    return acc;
}

fn day07p2(data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');
    var acc: usize = 0;

    var lasers = [_]usize{0} ** 141;

    const first = lines.next() orelse unreachable;
    for (0.., first) |i, c| {
        if (c == 'S') {
            lasers[i] = 1;
            break;
        }
    }

    while (lines.next()) |line| {
        for (0.., line) |i, c| {
            // If there is a laser above us
            if (c == '^' and lasers[i] >= 1) {
                lasers[i - 1] += lasers[i];
                lasers[i + 1] += lasers[i];
                lasers[i] = 0;
            }
        }
    }

    for (lasers) |l| {
        acc += l;
    }

    return acc;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day07(input);
    const p1_time = timer.lap();
    const result_p2 = try day07p2(input);
    const p2_time = timer.read();
    std.debug.print("day07 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day07 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{});
    defer bench.deinit();
    try bench.add("day07 p1", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day07(input) catch unreachable;
        }
    }.call, .{});
    try bench.add("day07 p2", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day07p2(input) catch unreachable;
        }
    }.call, .{});
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    try bench.run(stdout);
    try stdout.flush();
}

test "day07" {
    const result = try day07(input_test);
    const expect = 21;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

test "day07p2" {
    const result = try day07p2(input_test);
    const expect = 40;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}
