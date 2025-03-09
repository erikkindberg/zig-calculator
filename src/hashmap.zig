const std = @import("std");

const Entry = struct {
    key: []u8,
    value: f64,
    allocator: std.mem.Allocator,
    is_occupied: bool,
};

pub const HashMap = struct {
    entries: []Entry,
    capacity: usize,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, capacity: usize) !HashMap {
        const entries = try allocator.alloc(Entry, capacity);
        for (entries) |*entry| {
            entry.is_occupied = false;
        }
        return HashMap{
            .entries = entries,
            .capacity = capacity,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *HashMap) void {
        std.debug.print("Deinitializing HashMap with capacity {d}\n", .{self.capacity});
        var freed_count: usize = 0;

        for (self.entries, 0..) |*entry, i| {
            if (entry.is_occupied) {
                std.debug.print("Freeing entry at index {d}, key: '{s}'\n", .{ i, entry.key });
                entry.allocator.free(entry.key);
                freed_count += 1;
            }
        }

        std.debug.print("Freed {d} keys\n", .{freed_count});
        self.allocator.free(self.entries);
    }

    fn hash(self: *HashMap, key: []const u8) usize {
        var hash_value: u64 = 5381;

        for (key) |c| {
            hash_value = ((hash_value << 5) + hash_value) +% c;
        }

        const result = @as(usize, @intCast(hash_value % @as(u64, @intCast(self.capacity))));
        std.debug.print("Hash for '{s}': {d}\n", .{ key, result });
        return result;
    }

    pub fn put(self: *HashMap, key: []u8, value: f64, allocator: std.mem.Allocator) !void {
        const trimmed_key = std.mem.trim(u8, key, " \t\r\n");
        const key_copy = try allocator.dupe(u8, trimmed_key);
        errdefer allocator.free(key_copy); // Free on error

        var index = self.hash(key_copy);
        var attempts: usize = 0;

        while (self.entries[index].is_occupied) {
            if (attempts >= self.capacity) {
                // HashMap is full, free the key_copy to avoid leak
                allocator.free(key_copy);
                return error.HashMapFull;
            }
            if (std.mem.eql(u8, self.entries[index].key, key_copy)) {
                // Always    free the old key and use the new one
                self.entries[index].allocator.free(self.entries[index].key);
                self.entries[index].key = key_copy;
                self.entries[index].allocator = allocator;
                self.entries[index].value = value;
                return; // Key already exists, update the value
            }
            index = (index + 1) % self.capacity;
            attempts += 1;
        }
        self.entries[index] = Entry{
            .key = key_copy,
            .value = value,
            .allocator = allocator,
            .is_occupied = true,
        };
    }

    pub fn get(self: *HashMap, key: []const u8) ?f64 {
        const trimmed_key = std.mem.trim(u8, key, " \t\r\n");
        var index = self.hash(trimmed_key);
        while (self.entries[index].is_occupied) {
            if (std.mem.eql(u8, self.entries[index].key, trimmed_key)) {
                return self.entries[index].value;
            }
            index = (index + 1) % self.capacity;
        }
        return null;
    }

    pub fn remove(self: *HashMap, key: []const u8) bool {
        const trimmed_key = std.mem.trim(u8, key, " \t\r\n");
        var index = self.hash(trimmed_key);
        while (self.entries[index].is_occupied) {
            if (std.mem.eql(u8, self.entries[index].key, trimmed_key)) {
                self.entries[index].allocator.free(self.entries[index].key);
                self.entries[index].is_occupied = false;
                return true;
            }
            index = (index + 1) % self.capacity;
        }
        return false;
    }

    pub fn contains(self: *HashMap, key: []const u8) bool {
        // Add debug print to show what we're looking for

        const trimmed_key = std.mem.trim(u8, key, " \t\r\n");
        std.debug.print("Looking for key: '{s}'\n", .{trimmed_key});

        var index = self.hash(trimmed_key);
        // Print the initial hash index
        std.debug.print("Initial hash index: {d}\n", .{index});

        // Debug: check if the initial slot is occupied
        std.debug.print("Initial slot occupied: {}\n", .{self.entries[index].is_occupied});

        var attempts: usize = 0;
        while (attempts < self.capacity) {
            if (!self.entries[index].is_occupied) {
                // If we hit an empty slot, the key doesn't exist
                break;
            }

            std.debug.print("Checking index {d}, key: '{s}'\n", .{ index, self.entries[index].key });

            if (std.mem.eql(u8, self.entries[index].key, trimmed_key)) {
                std.debug.print("Found key '{s}' at index {d}\n", .{ trimmed_key, index });
                return true;
            }

            index = (index + 1) % self.capacity;
            attempts += 1;
        }

        std.debug.print("Key '{s}' not found after {d} attempts\n", .{ trimmed_key, attempts });
        return false;
    }
    pub fn printAllKeys(self: *HashMap) void {
        std.debug.print("All keys in the hashmap:\n", .{});

        var count: usize = 0;

        for (self.entries) |*entry| {
            if (entry.is_occupied) {
                std.debug.print("{d}: {s} = {d}\n", .{ count, entry.key, entry.value });
                count += 1;
            }
        }

        if (count == 0) {
            std.debug.print("(empty)\n", .{});
        }
    }
};
