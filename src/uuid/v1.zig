const std = @import("std");
const crypto = std.crypto;
const testing = std.testing;
const time = std.time;

pub const V1 = struct {
    // Binary layout
    //  0                   1                   2                   3
    //  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    // |                           time_low                            |
    // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    // |           time_mid            |  ver  |       time_high       |
    // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    // |var|         clock_seq         |             node              |
    // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    // |                              node                             |
    // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    //
    // time_low:
    // The least significant 32 bits of the 60-bit starting timestamp. Occupies bits 0 through 31 (octets 0-3).
    // time_mid:
    // The middle 16 bits of the 60-bit starting timestamp. Occupies bits 32 through 47 (octets 4-5).
    // ver:
    // The 4-bit version field as defined by Section 4.2, set to 0b0001 (1). Occupies bits 48 through 51 of octet 6.
    // time_high:
    // The least significant 12 bits from the 60-bit starting timestamp. Occupies bits 52 through 63 (octets 6-7).
    // var:
    // The 2-bit variant field as defined by Section 4.1, set to 0b10. Occupies bits 64 and 65 of octet 8.
    // clock_seq:
    // The 14 bits containing the clock sequence. Occupies bits 66 through 79 (octets 8-9).
    // node:
    // 48-bit spatially unique identifier. Occupies bits 80 through 127 (octets 10-15).

    const Self = @This();

    // 0x01b21dd213814000 is the number of 100-ns intervals between the
    // UUID epoch 1582-10-15 00:00:00 and the Unix epoch 1970-01-01 00:00:00.
    const lillian_diff: i128 = 0x01B2_1DD2_1381_4000;

    /// some sort of random incrementing counter kinda thing
    clock_seq: u16,
    /// device identifier (maybe a random number as well)
    node: [6]u8,
    /// keep track of the last 100ns interval when the timestamp was generated in case time moves backwards (does this actually happen ?)
    last_timestamp: i128 = 0,

    pub fn init(node: ?[6]u8) V1 {
        const clock_seq = (crypto.random.int(u16) & 0x3FFF);

        // the node segment is generated randomly but can be overriden during init
        const bytes: [6]u8 = node orelse blk: {
            var b: [6]u8 = undefined;
            crypto.random.bytes(&b);
            b[0] |= 0x1;

            break :blk b;
        };

        return .{
            .clock_seq = clock_seq,
            .node = bytes,
        };
    }

    pub fn generate(self: *Self) ![36]u8 {
        // TODO: windows is special epoch starts on jan 1 1601
        const now: i128 = @divTrunc(time.nanoTimestamp(), 100) + lillian_diff;
        const time_low = @as(u32, @intCast(now & 0xFFFF_FFFF));
        const time_mid = @as(u16, @intCast((now >> 32) & 0xFFFF));
        const time_high = @as(u16, @intCast((now >> 48) & 0xFFF)) | 0x1000; // set version in this segment as well

        if (now <= self.last_timestamp) {
            self.last_timestamp += 1;
        }

        const clock_seq_var: u16 = self.clock_seq | 0x8000;

        var buf: [36]u8 = undefined;
        _ = try std.fmt.bufPrint(
            &buf,
            "{x:0>8}-{x:0>4}-{x:0>4}-{x:0>4}-{x:0>12}",
            .{
                time_low,
                time_mid,
                time_high,
                clock_seq_var,
                std.mem.readInt(u48, &self.node, .big),
            },
        );
        return buf;
    }
};

test "returns a uuid v1" {
    var v1 = V1.init(null);
    const v = try v1.generate();
    try testing.expect(v.len == 36);
}
