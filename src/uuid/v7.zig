const std = @import("std");
const time = std.time;
const testing = std.testing;
const crypto = std.crypto;

pub const V7 = struct {
    // Bit Layout
    //  0                   1                   2                   3
    //  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    // |                           unix_ts_ms                          |
    // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    // |          unix_ts_ms           |  ver  |       rand_a          |
    // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    // |var|                        rand_b                             |
    // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    // |                            rand_b                             |
    // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    //
    // unix_ts_ms:
    // 48-bit big-endian unsigned number of the Unix Epoch timestamp in milliseconds as per Section 6.1. Occupies bits 0 through 47 (octets 0-5).
    // ver:
    // The 4-bit version field as defined by Section 4.2, set to 0b0111 (7). Occupies bits 48 through 51 of octet 6.
    // rand_a:
    // 12 bits of pseudorandom data to provide uniqueness as per Section 6.9 and/or optional constructs to guarantee additional monotonicity as per Section 6.2. Occupies bits 52 through 63 (octets 6-7).
    // var:
    // The 2-bit variant field as defined by Section 4.1, set to 0b10. Occupies bits 64 and 65 of octet 8.
    // rand_b:
    // The final 62 bits of pseudorandom data to provide uniqueness as per Section 6.9 and/or an optional counter to guarantee additional monotonicity as per Section 6.2. Occupies bits 66 through 127 (octets 8-15).

    const Self = @This();

    last_timestamp: u48 = 0,

    pub fn init() V7 {
        return .{};
    }

    pub fn generate(self: *Self) [36]u8 {
        var bytes: [16]u8 = undefined;
        crypto.random.bytes(bytes[6..]);
        const unix_ts: u48 = @intCast(time.milliTimestamp());

        self.last_timestamp = if (unix_ts < self.last_timestamp) self.last_timestamp + 1 else unix_ts;
        std.mem.writeInt(u48, bytes[0..6], self.last_timestamp, .big);

        bytes[6] = (bytes[6] & 0x0F) | 0x70;
        bytes[8] = (bytes[8] & 0x3F) | 0x80;

        const result: *[36]u8 = std.fmt.bytesToHex(bytes[0..4], .lower) ++
            "-" ++ std.fmt.bytesToHex(bytes[4..6], .lower) ++
            "-" ++ std.fmt.bytesToHex(bytes[6..8], .lower) ++
            "-" ++ std.fmt.bytesToHex(bytes[8..10], .lower) ++
            "-" ++ std.fmt.bytesToHex(bytes[10..], .lower);

        return result.*;
    }
};

test "generates a uuid v7" {
    var v7 = V7.init();
    const uuid = v7.generate();
    try testing.expect(uuid.len == 36);
}
