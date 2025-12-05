const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day04.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day04_test.txt"), "\n");

const Pos = struct {
    x: usize,
    y: usize,
};

const Vec2 = struct {
    x: i64,
    y: i64,
};

const dirs = [_]Vec2{
    .{ .x = -1, .y = -1 },
    .{ .x = -1, .y = 0 },
    .{ .x = -1, .y = 1 },
    .{ .x = 0, .y = -1 },
    .{ .x = 0, .y = 1 },
    .{ .x = 1, .y = 1 },
    .{ .x = 1, .y = 0 },
    .{ .x = 1, .y = -1 },
};

fn day04(data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');
    var acc: usize = 0;

    var rows_buffer: [140][]const u8 = undefined;
    var rows = std.ArrayList([]const u8).initBuffer(&rows_buffer);

    var x_poss_buffer: [140 * 140]Pos = undefined;
    var x_poss = std.ArrayList(Pos).initBuffer(&x_poss_buffer);

    var idx_row: usize = 0;
    while (lines.next()) |line| : (idx_row += 1) {
        for (0.., line) |idx_col, char| {
            if (char == '@') {
                x_poss.appendAssumeCapacity(.{ .x = idx_row, .y = idx_col });
            }
        }
        rows.appendAssumeCapacity(line);
    }

    // For each X, count the neighbors @.
    x_pos_loop: for (x_poss.items) |x_pos| {
        var count: usize = 0;
        for (dirs) |dir| {
            // Skip if out of bounds
            const check_x = @as(i64, @intCast(x_pos.x)) + dir.x;
            const check_y = @as(i64, @intCast(x_pos.y)) + dir.y;
            if (check_x >= rows.items.len or check_y >= rows.items[0].len or check_x < 0 or check_y < 0) {
                continue;
            }

            if (rows.items[@as(usize, @intCast(check_x))][@as(usize, @intCast(check_y))] == '@') {
                count += 1;
            }
            if (count >= 4) {
                continue :x_pos_loop;
            }
        }
        acc += 1;
    }

    return acc;
}

const Matrix = struct {
    data: []u8,
    cap: usize,
    row_cap: usize,
    row_size: usize = 0,
    total_rows: usize = 0,

    allocator: std.mem.Allocator,

    fn init(cap: usize, row_cap: usize, allocator: std.mem.Allocator) !Matrix {
        const data = try allocator.alloc(u8, cap * row_cap);
        return Matrix{
            .data = data,
            .cap = cap,
            .row_cap = row_cap,
            .allocator = allocator,
        };
    }

    fn deinit(self: *Matrix) void {
        self.allocator.free(self.data);
    }

    fn get(self: *const Matrix, x: usize, y: usize) u8 {
        return self.data[self.row_cap * x + y];
    }

    fn set(self: *Matrix, x: usize, y: usize, value: u8) void {
        self.data[self.row_cap * x + y] = value;
    }

    fn print(self: *const Matrix) void {
        for (0..self.total_rows) |idx_row| {
            for (0..self.row_size) |idx_col| {
                std.debug.print("{c}", .{self.get(idx_row, idx_col)});
            }
            std.debug.print("\n", .{});
        }
    }
};

const LinkedPos = struct {
    pos: Pos,
    node: std.DoublyLinkedList.Node,
};

fn day04p2(data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');
    var acc: usize = 0;

    var buffer: [140 * 140 * @sizeOf(u8) + 140 * 140 * @sizeOf(LinkedPos)]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const fba_allocator = fba.allocator();

    var x_poss = std.DoublyLinkedList{};
    var x_poss_len: usize = 0;

    var matrix = try Matrix.init(140, 140, fba_allocator);
    defer matrix.deinit();

    // Read everything
    while (lines.next()) |line| : (matrix.total_rows += 1) {
        if (matrix.row_size == 0) {
            matrix.row_size = line.len;
        } else if (matrix.row_size != line.len) {
            std.debug.panic("row size mismatch\n", .{});
        }
        for (0.., matrix.data[matrix.row_cap * matrix.total_rows .. matrix.row_cap * matrix.total_rows + line.len], line) |idx_col, *d, s| {
            if (s == '@') {
                const lpos = try fba_allocator.create(LinkedPos);
                lpos.* = .{
                    .pos = .{
                        .x = matrix.total_rows,
                        .y = idx_col,
                    },
                    .node = .{},
                };
                x_poss.append(&lpos.node);
                x_poss_len += 1;
            }
            d.* = s;
        }
    }

    // For each @, count the neighbors @.
    while (true) {
        var current_cleaned: usize = 0;
        const current_len = x_poss_len;
        x_pos_loop: for (0..current_len) |_| {
            // dequeue
            const x_pos_node = x_poss.popFirst() orelse unreachable;
            const x_pos: *LinkedPos = @fieldParentPtr("node", x_pos_node);
            var count: usize = 0;
            for (dirs) |dir| {
                // Skip if out of bounds
                const check_x = @as(i64, @intCast(x_pos.*.pos.x)) + dir.x;
                const check_y = @as(i64, @intCast(x_pos.*.pos.y)) + dir.y;
                if (check_x >= matrix.total_rows or check_y >= matrix.row_size or check_x < 0 or check_y < 0) {
                    continue;
                }

                if (matrix.get(@as(usize, @intCast(check_x)), @as(usize, @intCast(check_y))) == '@') {
                    count += 1;
                }
                if (count >= 4) {
                    // Requeue
                    x_poss.append(&x_pos.node);
                    continue :x_pos_loop;
                }
            }
            matrix.set(@as(usize, @intCast(x_pos.*.pos.x)), @as(usize, @intCast(x_pos.*.pos.y)), 'x');
            current_cleaned += 1;
            x_poss_len -= 1;
        }

        if (current_cleaned == 0) {
            break;
        }
        // matrix.print();
        acc += current_cleaned;
    }

    return acc;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day04(input);
    const p1_time = timer.lap();
    const result_p2 = try day04p2(input);
    const p2_time = timer.read();
    std.debug.print("day04 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day04 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{});
    defer bench.deinit();
    try bench.add("day04 p1", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day04(input) catch unreachable;
        }
    }.call, .{});
    try bench.add("day04 p2", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day04p2(input) catch unreachable;
        }
    }.call, .{});
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    try bench.run(stdout);
    try stdout.flush();
}

test "day04" {
    const result = try day04(input_test);
    const expect = 13;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

test "day04p2" {
    const result = try day04p2(input_test);
    const expect = 43;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}
