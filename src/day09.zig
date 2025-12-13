const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day09.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day09_test.txt"), "\n");

const Pos = struct {
    x: i64,
    y: i64,
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

fn area(a: Pos, b: Pos) usize {
    return (@abs(a.x - b.x) + 1) * (@abs(a.y - b.y) + 1);
}

fn day09(data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var poss_buffer: [1000]Pos = undefined;
    var poss = std.ArrayList(Pos).initBuffer(&poss_buffer);

    while (lines.next()) |line| {
        var scan_idx: usize = 0;
        const x = scanNumber(i64, line, &scan_idx) orelse unreachable;
        scan_idx += 1; // Skip ','
        const y = scanNumber(i64, line, &scan_idx) orelse unreachable;
        poss.appendAssumeCapacity(.{ .x = x, .y = y });
    }

    var max: usize = 0;
    for (0.., poss.items) |i, a| {
        for (0.., poss.items) |j, b| {
            if (i > j) { // Don't compute the same set of points
                max = @max(area(a, b), max);
            }
        }
    }

    return max;
}

// The idea is to find the among the set of rectangle we have, if its inside
// the large polygon (Collision detection).
// If so, find the max area.
fn day09p2(data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var poly_buffer: [1000]Pos = undefined;
    var path = std.ArrayList(Pos).initBuffer(&poly_buffer);

    while (lines.next()) |line| {
        var scan_idx: usize = 0;
        const x = scanNumber(i64, line, &scan_idx) orelse unreachable;
        scan_idx += 1; // Skip ','
        const y = scanNumber(i64, line, &scan_idx) orelse unreachable;
        path.appendAssumeCapacity(.{ .x = x, .y = y });
    }
    // Close the polygon. The list is ordered to make a polygon thankfully.
    path.appendAssumeCapacity(path.items[0]);

    var max: usize = 0;
    for (0.., path.items) |i, a| {
        for (0.., path.items) |j, b| {
            if (i > j) { // Don't compute the same set of points
                // Rectangle A
                // Corner closest to the origin
                const ax_min = @min(a.x, b.x);
                const ay_min = @min(a.y, b.y);
                // Corder farthest from the origin
                const ax_max = @max(a.x, b.x);
                const ay_max = @max(a.y, b.y);

                // The aim is to find the rectangles where the edges follows
                // the lines of the polygon, and the polygon never intersects
                // the rectangle.
                //
                // The method used is similar to AABB (Axis Aligned Bounding Box)
                // to detect collision between the rectangle and the edge of the
                // polygon.
                //
                // There might be an edge case where two edges of the polygon are
                // superposed. In this case, the algorithm will fail.
                //
                // However, it doesn't seems to be the case, and this permits
                // to detect if a rectangle is intersecting with the polygon. ("day09p2.1")
                var intersection_found = false;
                for (path.items[0 .. path.items.len - 1], path.items[1..path.items.len]) |c, d| {
                    // Rectangle B
                    // Corner closest to the origin
                    const bx_min = @min(c.x, d.x);
                    const by_min = @min(c.y, d.y);
                    // Corner farthest from the origin
                    const bx_max = @max(c.x, d.x);
                    const by_max = @max(c.y, d.y);
                    // Check if the line is strictly inside the rectangle. If yes,
                    // that's not good.
                    //
                    // Example (for illustration only, this example does NOT appear
                    // in the problem):
                    //
                    //     a_min-------|
                    //      |          |
                    //      |          |
                    //      |--------a_max   b_min----b_max
                    //
                    // ax_min < bx_max: true
                    // ay_min < by_max: true
                    // ax_max > bx_min: false
                    // ay_max > by_min: false
                    //
                    if (ax_min < bx_max and ay_min < by_max and ax_max > bx_min and ay_max > by_min) {
                        intersection_found = true;
                        break;
                    }
                }

                // TODO: Missing edge case where the largest rectangle is outside
                // the polygon.

                // No edges inside the rectangle, meaning the rectangle is inside
                // the polygon.
                if (!intersection_found) {
                    const ar = area(a, b);
                    if (max < ar) {
                        max = ar;
                        // std.debug.print("max: {} a: {} b: {}\n", .{ max, a, b });
                    }
                }
            }
        }
    }

    return max;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day09(input);
    const p1_time = timer.lap();
    const result_p2 = try day09p2(input);
    const p2_time = timer.read();
    std.debug.print("day09 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day09 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{});
    defer bench.deinit();
    try bench.add("day09 p1", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day09(input) catch unreachable;
        }
    }.call, .{});
    try bench.add("day09 p2", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day09p2(input) catch unreachable;
        }
    }.call, .{});
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    try bench.run(stdout);
    try stdout.flush();
}

test "day09" {
    const result = try day09(input_test);
    const expect = 50;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

test "day09p2" {
    const result = try day09p2(input_test);
    const expect = 24;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

test "day09p2.1" {
    // O.............
    // ..#XXXXXX#....
    // ..XX#XX#XX....
    // ..#X#..#X#....
    // ..............
    const result = try day09p2(
        \\2,1
        \\9,1
        \\9,3
        \\7,3
        \\7,2
        \\4,2
        \\4,3
        \\2,3
    );
    // Testing rectangle (a) 2,1 and 9,3 against the edges
    // Edge (b): 4,2 7,2
    // ax_min < bx_max: true
    // ay_min < by_max: true
    // ax_max > bx_min: true
    // ay_max > by_min: true
    // => Intersection

    // ..#XXXXX 2,1
    // ..XX#XX# 7,2
    const expect = 12;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

test "day09p2.2" {
    // O.............
    // ..#XXXXXX#....
    // ..XXXXXXXX....
    // ..#XXXXXX#....
    // ..............
    const result = try day09p2(
        \\2,1
        \\9,1
        \\9,3
        \\2,3
    );
    // Testing rectangle (a) 2,1 and 9,3 against the edges
    // Edge (b): 2,1 9,3
    // ax_min < bx_max: true
    // ay_min < by_max: true
    // ax_max > bx_min: false
    // ay_max > by_min: false
    // => No intersection
    const expect = 24; // Top line (2,1) and (9,1)
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

// Test Edge case
// test "day09p2.3" {
//     // O.............
//     // ..#XXXXXX#....
//     // ..#XXXXX#X....
//     // ........XX....
//     // ........##....
//     // ..............
//     const result = try day09p2(
//         \\2,1
//         \\9,1
//         \\9,4
//         \\8,4
//         \\8,2
//         \\2,2
//     );
//     // Testing rectangle (a) 2,2 and 8,4 against the edges
//     // Edge (b): 2,1 9,1
//     // ax_min < bx_max: true
//     // ay_min < by_max: false
//     // ...
//     // => No intersection
//     // Edge (b): 2,2 9,1
//     // ax_min < bx_max: true
//     // ay_min < by_max: false
//     // ...
//     // => No intersection
//     const expect = 16;
//     std.testing.expect(result == expect) catch |err| {
//         std.debug.print("got: {}, expect: {}\n", .{ result, expect });
//         return err;
//     };
// }
