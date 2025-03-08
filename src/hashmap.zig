const std = @import("std");

const Entry = struct {
    key: []const u8,
    value: f64,
    is_occupied: bool,
};

pub const HashMap = struct {
    entries: []Entry,
    capacity: usize,
    allocator: *std.mem.Allocator,

    pub fn init(allocator: *std.mem.Allocator, capacity: usize) !HashMap {
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
        self.allocator.free(self.entries);
    }

    fn hash(self: *HashMap, key: []const u8) usize {
        var hash_value: usize = 0;
        for (key) |c| {
            hash_value = hash_value * 31 + @as(usize, c);
        }
        return hash_value % self.capacity;
    }

    pub fn put(self: *HashMap, key: []const u8, value: f64) !void {
        var index = self.hash(key);
        while (self.entries[index].is_occupied) {
            if (std.mem.eql(u8, self.entries[index].key, key)) {
                self.entries[index].value = value;
                return;
            }
            index = (index + 1) % self.capacity;
        }
        self.entries[index] = Entry{
            .key = key,
            .value = value,
            .is_occupied = true,
        };
    }

    pub fn get(self: *HashMap, key: []const u8) ?f64 {
        var index = self.hash(key);
        while (self.entries[index].is_occupied) {
            if (std.mem.eql(u8, self.entries[index].key, key)) {
                return self.entries[index].value;
            }
            index = (index + 1) % self.capacity;
        }
        return null;
    }

    pub fn remove(self: *HashMap, key: []const u8) bool {
        var index = self.hash(key);
        while (self.entries[index].is_occupied) {
            if (std.mem.eql(u8, self.entries[index].key, key)) {
                self.entries[index].is_occupied = false;
                return true;
            }
            index = (index + 1) % self.capacity;
        }
        return false;
    }

    pub fn contains(self: *HashMap, key: []const u8) bool {
        var index = self.hash(key);
        while (self.entries[index].is_occupied) {
            if (std.mem.eql(u8, self.entries[index].key, key)) {
                return true;
            }
            index = (index + 1) % self.capacity;
        }
        return false;
    }
};
