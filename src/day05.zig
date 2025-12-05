const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day05.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day05_test.txt"), "\n");

const Range = struct {
    min: usize,
    max: usize,
};

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

fn day05(data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');
    var acc: usize = 0;

    var ranges_buffer: [187]Range = undefined;
    var ranges = std.ArrayList(Range).initBuffer(&ranges_buffer);

    // Ranges scan
    while (lines.next()) |line| {
        if (line.len == 0) {
            break;
        }
        var scan_idx: usize = 0;
        const min = scanNumber(usize, line, &scan_idx) orelse unreachable;
        scan_idx += 1; // Skip '-'
        const max = scanNumber(usize, line, &scan_idx) orelse unreachable;
        ranges.appendAssumeCapacity(.{ .min = min, .max = max });
    }

    // Test scan
    line_loop: while (lines.next()) |line| {
        var scan_idx: usize = 0;
        const value = scanNumber(usize, line, &scan_idx) orelse unreachable;

        for (ranges.items) |range| {
            if (value >= range.min and value <= range.max) {
                acc += 1;
                continue :line_loop;
            }
        }
    }

    return acc;
}

fn sortRanges(_: void, a: Range, b: Range) bool {
    return a.min < b.min;
}

fn day05p2(data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');
    var acc: usize = 0;

    var ranges_buffer: [187]Range = undefined;
    var ranges = std.ArrayList(Range).initBuffer(&ranges_buffer);

    // Ranges scan
    while (lines.next()) |line| {
        if (line.len == 0) {
            break;
        }
        var scan_idx: usize = 0;
        const min = scanNumber(usize, line, &scan_idx) orelse unreachable;
        scan_idx += 1; // Skip '-'
        const max = scanNumber(usize, line, &scan_idx) orelse unreachable;
        ranges.appendAssumeCapacity(.{ .min = min, .max = max });
    }

    std.mem.sort(Range, ranges.items, {}, sortRanges);

    var prev_max: usize = 0;
    for (ranges.items) |range| {
        if (range.max <= prev_max) {
            continue;
        }

        acc += range.max - @max(range.min, prev_max + 1) + 1;
        prev_max = @max(range.max, prev_max);
    }

    return acc;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day05(input);
    const p1_time = timer.lap();
    const result_p2 = try day05p2(input);
    const p2_time = timer.read();
    std.debug.print("day05 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day05 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{});
    defer bench.deinit();
    try bench.add("day05 p1", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day05(input) catch unreachable;
        }
    }.call, .{});
    try bench.add("day05 p2", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day05p2(input) catch unreachable;
        }
    }.call, .{});
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    try bench.run(stdout);
    try stdout.flush();
}

test "day05" {
    const result = try day05(input_test);
    const expect = 3;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

test "day05p2" {
    const result = try day05p2(input_test);
    const expect = 14;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}
