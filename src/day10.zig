const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day10.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day10_test.txt"), "\n");

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

fn scanTarget(data: []const u8, idx: *usize) usize {
    if (data[idx.*] == '[') idx.* += 1;
    // Don't check "out_idx < output.len" and force a crash.
    var output: usize = 0;
    var pos: u6 = 0;
    while (data[idx.*] != ']') : ({
        idx.* += 1;
        pos += 1;
    }) {
        if (data[idx.*] == '#') output |= @as(usize, 1) << pos;
    }
    idx.* += 1; // Skip ']'
    return output;
}

// Use BFS to find the right button combination
fn bfs(
    allocator: std.mem.Allocator,
    target: usize,
    buttons: []usize,
) !usize {
    var visited = std.AutoHashMap(usize, usize).init(allocator);
    defer visited.deinit();

    var queue = std.ArrayList(usize).empty;
    defer queue.deinit(allocator);

    try visited.put(0, 0); // Set initial state (0 = no buttons pressed)
    try queue.append(allocator, 0);

    while (queue.items.len > 0) {
        const current = queue.orderedRemove(0); // Dequeue the first element
        const count = visited.get(current) orelse unreachable; // Should be initialized
        for (buttons) |button| {
            const next = current ^ button; // Toggle button
            const next_count = count + 1;
            if (next == target) {
                return next_count;
            }

            if (visited.get(next) == null) {
                try visited.put(next, next_count);
                try queue.append(allocator, next); // Enqueue state
            }
        }
    }

    // The exercise should be solvable.
    unreachable;
}

fn day10(allocator: std.mem.Allocator, data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');
    var acc: usize = 0;

    // Allocate memory. Since the lines are independent, we can reuse the same buffer.
    // Format in binary instead of an array of bool to save space.
    var button_buffer: [20]usize = undefined;

    while (lines.next()) |line| {
        var scan_idx: usize = 0;
        var buttons = std.ArrayList(usize).initBuffer(&button_buffer);
        const target = scanTarget(line, &scan_idx);
        scan_idx += 1; // Skip space
        while (line[scan_idx] != '{') {
            var button: usize = 0;
            // Comma-separated, space-separated, single digit,
            scan_idx += 1; // Skip '('
            while (line[scan_idx] != ' ') {
                const v = line[scan_idx] - '0';
                button |= @as(usize, 1) << @as(u6, @intCast(v));
                scan_idx += 1;
                scan_idx += 1; // Skip potential comma or ')'
            }
            scan_idx += 1; // Skip space
            buttons.appendAssumeCapacity(button);
        }

        // We ignore the joltage for part 1

        // Execute the BFS
        acc += try bfs(allocator, target, buttons.items);
    }

    return acc;
}

fn day10p2(_: []const u8) !usize {
    return 0;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day10(std.heap.page_allocator, input);
    const p1_time = timer.lap();
    const result_p2 = try day10p2(input);
    const p2_time = timer.read();
    std.debug.print("day10 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day10 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{});
    defer bench.deinit();
    try bench.add("day10 p1", struct {
        pub fn call(allocator: std.mem.Allocator) void {
            _ = day10(allocator, input) catch unreachable;
        }
    }.call, .{});
    try bench.add("day10 p2", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day10p2(input) catch unreachable;
        }
    }.call, .{});
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    try bench.run(stdout);
    try stdout.flush();
}

test "day10" {
    const result = try day10(std.heap.page_allocator, input_test);
    const expect = 7;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

// test "day10p2" {
//     const result = try day10p2(input_test);
//     const expect = 24;
//     std.testing.expect(result == expect) catch |err| {
//         std.debug.print("got: {}, expect: {}\n", .{ result, expect });
//         return err;
//     };
// }
