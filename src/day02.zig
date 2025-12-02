const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day02.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day02_test.txt"), "\n");

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

fn itoa(value: usize, buf: []u8) []u8 {
    const digits = "0123456789";

    if (value == 0) {
        buf[0] = '0';
        return buf[0..1];
    }

    var abs_value = @abs(value);
    const digit_count = std.math.log10_int(abs_value) + 1;

    for (0..digit_count) |i| {
        buf[(digit_count) - i - 1] = digits[@rem(abs_value, 10)];
        abs_value = @divTrunc(abs_value, 10);
    }

    return (buf[0..digit_count]);
}

fn isRepeatingPattern(data: []const u8) bool {
    if (@rem(data.len, 2) != 0) { // Odd
        return false;
    }

    return std.mem.eql(u8, data[0 .. data.len / 2], data[data.len / 2 .. data.len]);
}

fn day02(data: []const u8) !usize {
    var ranges = std.mem.splitScalar(u8, data, ',');
    var acc: usize = 0;
    var buf: [11]u8 = undefined;

    while (ranges.next()) |range| {
        var ch_idx: usize = 0;
        const low = scanNumber(usize, range, &ch_idx) orelse unreachable;
        ch_idx += 1; // Skip '-'
        const high = scanNumber(usize, range, &ch_idx) orelse unreachable;

        for (low..high + 1) |i| {
            const i_str = itoa(i, &buf);
            if (isRepeatingPattern(i_str)) {
                acc += i;
            }
        }
    }

    return acc;
}

fn isRepeatingPatterns(data: []const u8) bool {
    var size: usize = data.len / 2;
    checks: while (size > 0) : (size -= 1) {
        // If there is not enough spaces to fit the pattern.
        if (size != 1 and @rem(data.len, size) != 0) {
            continue;
        }

        // Number of checks
        const checks = data.len / size - 1; // -1 to remove the initial check
        for (1..checks + 1) |i| {
            // std.debug.print("check {s}: {s} ({}-{}) in {s}\n", .{ data[0..size], data[i + 1 * size .. (i + 1) * size], i * size, (i + 1) * size, data });
            if (std.mem.eql(u8, data[0..size], data[i * size .. (i + 1) * size])) {
                continue;
            }
            continue :checks;
        }
        // std.debug.print("ok\n", .{});
        return true;
    }

    return false;
}

fn day02p2(data: []const u8) !usize {
    var ranges = std.mem.splitScalar(u8, data, ',');
    var acc: usize = 0;
    var buf: [11]u8 = undefined;

    while (ranges.next()) |range| {
        var ch_idx: usize = 0;
        const low = scanNumber(usize, range, &ch_idx) orelse unreachable;
        ch_idx += 1; // Skip '-'
        const high = scanNumber(usize, range, &ch_idx) orelse unreachable;

        // std.debug.print("low: {d}, high: {d}\n", .{ low, high });
        for (low..high + 1) |i| {
            const i_str = itoa(i, &buf);
            if (isRepeatingPatterns(i_str)) {
                // std.debug.print("found: {s}\n", .{i_str});
                acc += i;
            }
        }
    }

    return acc;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day02(input);
    const p1_time = timer.lap();
    const result_p2 = try day02p2(input);
    const p2_time = timer.read();
    std.debug.print("day02 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day02 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{});
    defer bench.deinit();
    try bench.add("day02 p1", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day02(input) catch unreachable;
        }
    }.call, .{});
    try bench.add("day02 p2", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day02p2(input) catch unreachable;
        }
    }.call, .{});
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    try bench.run(stdout);
    try stdout.flush();
}

test "day02" {
    const result = try day02(input_test);
    const expect = 1227775554;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

test "day02p2" {
    const result = try day02p2(input_test);
    const expect = 4174379265;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}
