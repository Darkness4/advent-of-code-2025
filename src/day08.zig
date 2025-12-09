const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day08.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day08_test.txt"), "\n");

const Pos = struct {
    x: i64,
    y: i64,
    z: i64,
};

fn comb(n: usize, r: usize) usize {
    var res: usize = 1;
    var i: usize = 1;
    while (i <= r) : (i += 1) {
        res *= n - i + 1;
        res /= i;
    }
    return res;
}

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

fn distance(a: Pos, b: Pos) i64 {
    const dx = a.x - b.x;
    const dy = a.y - b.y;
    const dz = a.z - b.z;
    return dx * dx + dy * dy + dz * dz;
}

const Edge = struct {
    a: usize,
    b: usize,
    a_pos: Pos,
    b_pos: Pos,
    dist: i64,
};

fn sortEdges(_: void, a: Edge, b: Edge) bool {
    return a.dist < b.dist;
}

const DisjointUnionSet = struct {
    parents: []usize,
    sizes: []usize,

    fn initBuffer(parents_buffer: []usize, sizes_buffer: []usize) DisjointUnionSet {
        for (0.., parents_buffer) |i, *parent| {
            parent.* = i; // Each element is in its own set
            sizes_buffer[i] = 1;
        }

        return DisjointUnionSet{
            .parents = parents_buffer,
            .sizes = sizes_buffer,
        };
    }

    // find returns the root of the set containing x, with path compression
    fn find(self: *DisjointUnionSet, x: usize) usize {
        var root = x;
        while (self.parents[root] != root) {
            root = self.parents[root];
        }
        // Path compression: make all nodes on path point directly to root
        var curr = x;
        while (self.parents[curr] != curr) {
            const next = self.parents[curr];
            self.parents[curr] = root;
            curr = next;
        }
        return root;
    }

    fn union_sets(self: *DisjointUnionSet, a: usize, b: usize) void {
        var a_root = self.find(a);
        var b_root = self.find(b);
        if (a_root == b_root) return;

        // Take the largest set
        if (self.sizes[a_root] < self.sizes[b_root]) {
            std.mem.swap(usize, &a_root, &b_root);
        }

        // Append a_root to b set
        self.parents[b_root] = a_root;
        // Update size
        self.sizes[a_root] += self.sizes[b_root];
    }
};

// The aim is to use Kruskal's algorithm
fn day08(data: []const u8, comptime max_pairs: usize) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var poss_buffer: [1000]Pos = undefined;
    var poss = std.ArrayList(Pos).initBuffer(&poss_buffer);

    while (lines.next()) |line| {
        var scan_idx: usize = 0;
        const x = scanNumber(i64, line, &scan_idx) orelse unreachable;
        scan_idx += 1; // Skip ','
        const y = scanNumber(i64, line, &scan_idx) orelse unreachable;
        scan_idx += 1; // Skip ' '
        const z = scanNumber(i64, line, &scan_idx) orelse unreachable;
        poss.appendAssumeCapacity(.{ .x = x, .y = y, .z = z });
    }

    var edge_buffer: [comb(1000, 2)]Edge = undefined;
    var edges = std.ArrayList(Edge).initBuffer(&edge_buffer);

    for (0.., poss.items) |i, a| {
        for (0.., poss.items) |j, b| {
            if (i > j) { // Don't compute the same set of points
                edges.appendAssumeCapacity(.{
                    .a = i,
                    .a_pos = a,
                    .b = j,
                    .b_pos = b,
                    .dist = distance(a, b),
                });
            }
        }
    }

    // Kruskal's algorithm
    var dsu_parents_buffer: [1000]usize = undefined;
    var dsu_sizes_buffer: [1000]usize = undefined;
    var dsu: DisjointUnionSet = DisjointUnionSet.initBuffer(
        dsu_parents_buffer[0..poss.items.len],
        dsu_sizes_buffer[0..poss.items.len],
    );

    // For each Edges ordered by increasing weight
    std.mem.sort(Edge, edges.items, {}, sortEdges);
    // IMPORTANT: After making the X shortest connections. That include connexions
    // in the same set:
    //
    // > The next two junction boxes are 431,825,988 and 425,690,689. Because
    // > these two junction boxes were **already in the same circuit**, nothing happens!
    //
    // This means a connection to the same set is counted. The exercise description
    // indicates the limit of connections to be made.
    for (edges.items[0..max_pairs]) |edge| {
        // If they are not in the same set, but they are the closest, connect
        if (dsu.find(edge.a) != dsu.find(edge.b)) {
            // std.debug.print("{} {} {}\n", .{ edge.a_pos, edge.b_pos, edge.dist });
            dsu.union_sets(edge.a, edge.b);
        }
    }

    // At this point, the shortest pairs are connected to a root
    // Check each element and classify them in dsu (i.e, measure the number of members in each set)
    var seen = [_]bool{false} ** 1000;
    var sizes_buffer: [1000]usize = undefined;
    var sizes = std.ArrayList(usize).initBuffer(&sizes_buffer);
    for (0..poss.items.len) |i| {
        const root = dsu.find(i);
        if (!seen[root]) {
            seen[root] = true;
            sizes.appendAssumeCapacity(dsu.sizes[root]);
        }
    }

    // Find the biggest sets
    std.mem.sort(usize, sizes.items, {}, std.sort.desc(usize));
    // std.debug.print("first: {}, second: {}, third: {}\n", .{ sizes.items[0], sizes.items[1], sizes.items[2] });
    return sizes.items[0] * sizes.items[1] * sizes.items[2];
}

fn day08p2(data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var poss_buffer: [1000]Pos = undefined;
    var poss = std.ArrayList(Pos).initBuffer(&poss_buffer);

    while (lines.next()) |line| {
        var scan_idx: usize = 0;
        const x = scanNumber(i64, line, &scan_idx) orelse unreachable;
        scan_idx += 1; // Skip ','
        const y = scanNumber(i64, line, &scan_idx) orelse unreachable;
        scan_idx += 1; // Skip ' '
        const z = scanNumber(i64, line, &scan_idx) orelse unreachable;
        poss.appendAssumeCapacity(.{ .x = x, .y = y, .z = z });
    }

    var edge_buffer: [comb(1000, 2)]Edge = undefined;
    var edges = std.ArrayList(Edge).initBuffer(&edge_buffer);

    for (0.., poss.items) |i, a| {
        for (0.., poss.items) |j, b| {
            if (i > j) { // Don't compute the same set of points
                edges.appendAssumeCapacity(.{
                    .a = i,
                    .a_pos = a,
                    .b = j,
                    .b_pos = b,
                    .dist = distance(a, b),
                });
            }
        }
    }

    // Kruskal's algorithm
    var dsu_parents_buffer: [1000]usize = undefined;
    var dsu_sizes_buffer: [1000]usize = undefined;
    var dsu: DisjointUnionSet = DisjointUnionSet.initBuffer(
        dsu_parents_buffer[0..poss.items.len],
        dsu_sizes_buffer[0..poss.items.len],
    );

    // For each Edges ordered by increasing weight
    std.mem.sort(Edge, edges.items, {}, sortEdges);
    var last_edge: ?Edge = null;
    for (edges.items) |edge| {
        // If they are not in the same set, but they are the closest, connect
        if (dsu.find(edge.a) != dsu.find(edge.b)) {
            // std.debug.print("{} {} {}\n", .{ edge.a_pos, edge.b_pos, edge.dist });
            dsu.union_sets(edge.a, edge.b);
            last_edge = edge;
        }
    }

    return @as(usize, @intCast(last_edge.?.a_pos.x * last_edge.?.b_pos.x));
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day08(input, 1000);
    const p1_time = timer.lap();
    const result_p2 = try day08p2(input);
    const p2_time = timer.read();
    std.debug.print("day08 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day08 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{
        .iterations = 5,
    });
    defer bench.deinit();
    try bench.add("day08 p1", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day08(input, 1000) catch unreachable;
        }
    }.call, .{});
    try bench.add("day08 p2", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day08p2(input) catch unreachable;
        }
    }.call, .{});
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    try bench.run(stdout);
    try stdout.flush();
}

test "day08" {
    const result = try day08(input_test, 10);
    const expect = 40;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

test "day08p2" {
    const result = try day08p2(input_test);
    const expect = 25272;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}
