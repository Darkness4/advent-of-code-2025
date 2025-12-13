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
    var buttons = std.ArrayList(usize).initBuffer(&button_buffer);

    while (lines.next()) |line| {
        var scan_idx: usize = 0;
        buttons.clearRetainingCapacity();
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

fn AutoHashSet(comptime T: type) type {
    return std.AutoHashMap(T, void);
}

const State = struct {
    joltages: []usize,
    count: usize,

    fn hash(self: State) u64 {
        var h = std.hash.Wyhash.init(0);
        h.update(std.mem.asBytes(&self.count));
        h.update(std.mem.sliceAsBytes(self.joltages));
        return h.final();
    }
};

fn listOptions(
    allocator: std.mem.Allocator,
    target: usize,
    buttons: []usize,
    out: *AutoHashSet(usize),
) !void {
    var visited = std.AutoHashMap(usize, usize).init(allocator);
    defer visited.deinit();

    var queue = std.ArrayList(usize).empty;
    defer queue.deinit(allocator);

    try visited.put(0, 0); // Set initial state (0 = no buttons pressed)
    try queue.append(allocator, 0);

    // std.debug.print("target: {b}\n", .{target});

    while (queue.items.len > 0) {
        const button_state = queue.orderedRemove(0); // Dequeue the first element
        const current = visited.get(button_state) orelse unreachable; // Should be initialized
        for (0.., buttons) |i, button| {
            const next = current ^ button; // Tooggle button
            const next_button_state = button_state ^ @as(usize, 1) << @as(u6, @intCast(i));
            if (next == target) {
                try out.put(next_button_state, {});
                continue;
            }

            if (visited.get(next_button_state) == null) {
                try visited.put(next_button_state, next);
                try queue.append(allocator, next_button_state); // Enqueue state
            }
        }
    }

    return;
}

const CacheKeyContext = struct {
    pub fn hash(_: CacheKeyContext, key: []usize) u64 {
        return std.hash.Wyhash.hash(0, std.mem.sliceAsBytes(key));
    }

    pub fn eql(_: CacheKeyContext, a: []usize, b: []usize) bool {
        return std.mem.eql(usize, a, b);
    }
};

fn dfs(
    allocator: std.mem.Allocator,
    cache: *std.HashMap([]usize, usize, CacheKeyContext, std.hash_map.default_max_load_percentage),
    joltages: []usize,
    buttons: []usize,
    options: *std.AutoHashMap(usize, *AutoHashSet(usize)),
) !usize {
    if (cache.get(joltages)) |v| {
        // std.debug.print("cache hit: {any}\n", .{joltages});
        return v;
    }

    // Exit condition: No joltage = Success
    var sum_joltage: usize = 0;
    for (joltages) |j| {
        sum_joltage += j;
    }
    if (sum_joltage == 0) return 0;

    var min_button_pushed: usize = 10000000;
    var parity: usize = 0;
    for (0.., joltages) |i, v| {
        parity ^= @as(usize, v % 2) << @as(u6, @intCast(i));
    }

    // Compute the list of options (set of button to be push so the joltage is reduced)
    if (options.get(parity) == null) {
        const opts_set = try allocator.create(AutoHashSet(usize));
        opts_set.* = AutoHashSet(usize).init(allocator);
        try listOptions(allocator, parity, buttons, opts_set);
        try options.put(parity, opts_set);
    }
    const opts = options.get(parity) orelse unreachable;
    var it = opts.keyIterator();

    option_loop: while (it.next()) |option| {
        // std.debug.print("option: {b}\n", .{option.*});
        var next_joltages = try std.ArrayList(usize).initCapacity(allocator, joltages.len);
        for (0..joltages.len) |i| {
            next_joltages.appendAssumeCapacity(joltages[i]);
        }

        // Update joltage
        var opt = option.*;
        var button_idx: usize = 0;
        var button_pushed: usize = 0;
        // Binary representation of the set of button:
        // 1010 means button 1 and button 3 are pressed.
        while (opt > 0) : ({
            opt >>= 1;
            button_idx += 1;
        }) {
            if (opt & 1 == 1) { // Button is pushed
                var b = buttons[button_idx];
                // std.debug.print("b: {b}\n", .{b});
                for (next_joltages.items) |*j| {
                    const v, const overflow = @subWithOverflow(j.*, b & 1);
                    if (overflow > 0) { // Not enough joltage
                        continue :option_loop;
                    }
                    j.* = v;
                    b >>= 1;
                }
                button_pushed += 1;
            }
        }
        for (next_joltages.items) |*j| {
            j.* = j.* / 2;
        }
        const new_pressed = try dfs(allocator, cache, next_joltages.items, buttons, options);
        min_button_pushed = @min(min_button_pushed, button_pushed + 2 * new_pressed);
    }

    try cache.put(joltages, min_button_pushed);
    return min_button_pushed;
}

// https://www.reddit.com/r/adventofcode/comments/1pk87hl/2025_day_10_part_2_bifurcate_your_way_to_victory/
fn day10p2(allocator: std.mem.Allocator, data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');
    var acc: usize = 0;

    // Allocate memory. Since the lines are independent, we can reuse the same buffer.
    // Format in binary instead of an array of bool to save space.
    var button_buffer: [20]usize = undefined;
    var buttons = std.ArrayList(usize).initBuffer(&button_buffer);

    var joltage_buffer: [20]usize = undefined;
    var joltages = std.ArrayList(usize).initBuffer(&joltage_buffer);

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    var cache = std.HashMap([]usize, usize, CacheKeyContext, std.hash_map.default_max_load_percentage).init(arena_allocator);

    var options = std.AutoHashMap(usize, *AutoHashSet(usize)).init(arena_allocator);

    while (lines.next()) |line| {
        buttons.clearRetainingCapacity();
        joltages.clearRetainingCapacity();
        cache.clearRetainingCapacity();
        options.clearRetainingCapacity();

        var scan_idx: usize = 0;

        // We ignore the target for part 2
        _ = scanTarget(line, &scan_idx);

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
        scan_idx += 1; // Skip '{'
        // std.debug.print("buttons: {any}\n", .{buttons.items});

        // Scan joltages
        while (scanNumber(usize, line, &scan_idx)) |v| : (scan_idx += 1) {
            joltages.appendAssumeCapacity(v);
        }

        // Execute the BFS
        const res = try dfs(arena_allocator, &cache, joltages.items, buttons.items, &options);
        // std.debug.print("res {}\n", .{res});
        acc += res;
    }

    return acc;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day10(std.heap.page_allocator, input);
    const p1_time = timer.lap();
    const result_p2 = try day10p2(std.heap.page_allocator, input);
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
        pub fn call(allocator: std.mem.Allocator) void {
            _ = day10p2(allocator, input) catch unreachable;
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

test "day10p2" {
    const result = try day10p2(std.heap.page_allocator, input_test);
    const expect = 33;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}
