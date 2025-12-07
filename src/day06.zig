const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day06.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day06_test.txt"), "\n");

/// scanNumber scans a number in a string. Much more efficient than std.fmt.parseInt
/// since we ignore '-' and other characters that could define a number (like hex, etc...).
/// A very naive implementation, yet the fastest for Advent of Code.
/// Special for day06: skip leading spaces
fn scanNumber(comptime T: type, data: []const u8, idx: *usize) ?T {
    var number: ?T = null;
    if (idx.* >= data.len) return number;
    var char = data[idx.*];
    // Skip leading spaces
    while (char == ' ') {
        idx.* += 1;
        if (idx.* >= data.len) break;
        char = data[idx.*];
    }
    while (char >= '0' and char <= '9') {
        const v = char - '0';
        number = if (number) |n| n * 10 + (char - '0') else v;
        idx.* += 1;
        if (idx.* >= data.len) break;
        char = data[idx.*];
    }
    return number;
}

fn scanOperator(data: []const u8, idx: *usize) ?u8 {
    if (idx.* >= data.len) return null;
    var char = data[idx.*];
    // Skip leading spaces
    while (char == ' ') {
        idx.* += 1;
        if (idx.* >= data.len) break;
        char = data[idx.*];
    }
    return char;
}

fn day06(data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');
    var acc: usize = 0;

    // HACK: Hard code number of data lines.
    // For test data, add a new line between data and op line.
    const n_lines: usize = 4;

    const data_lines: [n_lines][]const u8 = [_][]const u8{
        lines.next() orelse unreachable,
        lines.next() orelse unreachable,
        lines.next() orelse unreachable,
        lines.next() orelse unreachable,
    };
    const op_line: []const u8 = lines.next() orelse unreachable;

    var prev_op_line_idx: usize = 0;
    var op_line_idx: usize = 1;
    // Read ahead once to determine the scope length
    var prev_op = op_line[0]; // Should be defined
    var op = scanOperator(op_line, &op_line_idx);
    while (true) : ({
        if (op) |o| {
            prev_op = o;
        } else break;
        op_line_idx += 1;
        op = scanOperator(op_line, &op_line_idx);
    }) {
        if (prev_op_line_idx >= op_line.len) {
            break;
        }

        // Scan number
        var numbers = [_]usize{0} ** 4;
        for (0..n_lines) |i| {
            var scan_idx: usize = 0;
            // std.debug.print("{s}\n", .{data_lines[i][@min(prev_op_line_idx, data_lines[i].len)..@min(op_line_idx, data_lines[i].len)]});
            numbers[i] = scanNumber(usize, data_lines[i][@min(prev_op_line_idx, data_lines[i].len)..@min(op_line_idx, data_lines[i].len)], &scan_idx) orelse if (prev_op == '*') 1 else 0;
        }

        // std.debug.print("{c} {d} {d} {d} {d}\n", .{ prev_op, numbers[0], numbers[1], numbers[2], numbers[3] });

        switch (prev_op) {
            '+' => {
                for (numbers) |number| {
                    acc += number;
                }
            },
            '*' => {
                var prod: usize = 1;
                for (numbers) |number| {
                    prod *= number;
                }
                acc += prod;
            },
            else => {
                // std.debug.print("unknown op: {c}\n", .{op});
                unreachable;
            },
        }

        prev_op_line_idx = op_line_idx;
    }

    return acc;
}

fn day06p2(data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');
    var acc: usize = 0;

    // HACK: Hard code number of data lines.
    // For test data, add a new line between data and op line.
    const n_lines: usize = 4;

    const data_lines: [n_lines][]const u8 = [_][]const u8{
        lines.next() orelse unreachable,
        lines.next() orelse unreachable,
        lines.next() orelse unreachable,
        lines.next() orelse unreachable,
    };
    const op_line: []const u8 = lines.next() orelse unreachable;

    var numbers_buffer: [6]usize = undefined;
    var numbers = std.ArrayList(usize).initBuffer(&numbers_buffer);

    var prev_op_line_idx: usize = 0;
    var op_line_idx: usize = 1;
    // Read ahead once to determine the scope length
    var prev_op = op_line[0]; // Should be defined
    var op = scanOperator(op_line, &op_line_idx);
    while (true) : ({
        if (op) |o| {
            prev_op = o;
        } else break;
        op_line_idx += 1;
        op = scanOperator(op_line, &op_line_idx);
    }) {
        if (prev_op_line_idx >= op_line.len) {
            break;
        }

        // Scan number by columns
        const size = op_line_idx - prev_op_line_idx;
        numbers.clearRetainingCapacity();
        for (0..size) |i| {
            var scan_idx: usize = 0;
            // HACK: We know the max line is 4
            const number_str: [4]u8 = [_]u8{
                if (prev_op_line_idx + i < data_lines[1].len) data_lines[0][prev_op_line_idx + i] else ' ',
                if (prev_op_line_idx + i < data_lines[2].len) data_lines[1][prev_op_line_idx + i] else ' ',
                if (prev_op_line_idx + i < data_lines[3].len) data_lines[2][prev_op_line_idx + i] else ' ',
                if (prev_op_line_idx + i < data_lines[3].len) data_lines[3][prev_op_line_idx + i] else ' ',
            };
            // std.debug.print("{s} i: {d}\n", .{ number_str, i });
            numbers.appendAssumeCapacity(scanNumber(usize, &number_str, &scan_idx) orelse if (prev_op == '*') 1 else 0);
        }

        switch (prev_op) {
            '+' => {
                for (numbers.items) |number| {
                    acc += number;
                }
            },
            '*' => {
                var prod: usize = 1;
                for (numbers.items) |number| {
                    prod *= number;
                }
                acc += prod;
            },
            else => {
                // std.debug.print("unknown op: {c}\n", .{op});
                unreachable;
            },
        }

        prev_op_line_idx = op_line_idx;
    }

    return acc;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day06(input);
    const p1_time = timer.lap();
    const result_p2 = try day06p2(input);
    const p2_time = timer.read();
    std.debug.print("day06 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day06 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{});
    defer bench.deinit();
    try bench.add("day06 p1", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day06(input) catch unreachable;
        }
    }.call, .{});
    try bench.add("day06 p2", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day06p2(input) catch unreachable;
        }
    }.call, .{});
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    try bench.run(stdout);
    try stdout.flush();
}

test "day06" {
    const result = try day06(input_test);
    const expect = 4277556;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

test "day06p2" {
    const result = try day06p2(input_test);
    const expect = 3263827;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}
