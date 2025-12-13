const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day12.txt"), "\n");

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

fn day12(data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var acc: usize = 0;

    var line_idx: usize = 0;
    while (line_idx < 30) : (line_idx += 1) {
        _ = lines.next() orelse unreachable;
    }

    // Because the input is too easy (shape sare small and area are pretty big),
    // we can just try to compute if we can fit the shapes in the area
    while (lines.next()) |line| {
        var scan_idx: usize = 0;
        var shapes_total_area: usize = 0;
        const w = scanNumber(usize, line, &scan_idx) orelse unreachable;
        scan_idx += 1; // Skip 'x'
        const h = scanNumber(usize, line, &scan_idx) orelse unreachable;
        scan_idx += 2; // Skip ': '
        while (scanNumber(usize, line, &scan_idx)) |n| : (scan_idx += 1) {
            shapes_total_area += n; // n * 3x3 shapes
        }
        if (w * h >= shapes_total_area * 3 * 3) acc += 1;
    }

    return acc;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day12(input);
    const p1_time = timer.lap();
    std.debug.print("day12 p1: {} in {}ns\n", .{ result_p1, p1_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{});
    defer bench.deinit();
    try bench.add("day12 p1", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day12(input) catch unreachable;
        }
    }.call, .{});
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    try bench.run(stdout);
    try stdout.flush();
}
