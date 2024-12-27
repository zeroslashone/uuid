const std = @import("std");
const crypto = std.crypto;
const testing = std.testing;

pub const V4 = struct {
    const uuidFmt = "{x}{x}{x}{x}-{x}{x}-{x}{x}-{x}{x}-{x}{x}{x}{x}{x}{x}";
    // Bit Layout
    //  0                   1                   2                   3
    //  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    // |                           random_a                            |
    // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    // |          random_a             |  ver  |       random_b        |
    // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    // |var|                       random_c                            |
    // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    // |                           random_c                            |
    // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    //
    // random_a:
    // The first 48 bits of the layout that can be filled with random data as specified in Section 6.9. Occupies bits 0 through 47 (octets 0-5).
    // ver:
    // The 4-bit version field as defined by Section 4.2, set to 0b0100 (4). Occupies bits 48 through 51 of octet 6.
    // random_b:
    // 12 more bits of the layout that can be filled random data as per Section 6.9. Occupies bits 52 through 63 (octets 6-7).
    // var:
    // The 2-bit variant field as defined by Section 4.1, set to 0b10. Occupies bits 64 and 65 of octet 8.
    // random_c:
    // The final 62 bits of the layout immediately following the var field to be filled with random data as per Section 6.9. Occupies bits 66 through 127 (octets 8-15).

    const Self = @This();

    pub fn init() V4 {
        return .{};
    }

    pub fn generate(_: *Self) [36]u8 {
        var bytes: [16]u8 = undefined;
        crypto.random.bytes(&bytes);
        bytes[6] = (bytes[6] & 0x0F) | 0x40;
        bytes[8] = (bytes[8] & 0x3F) | 0x80;

        const result: *[36]u8 = std.fmt.bytesToHex(bytes[0..4], .lower) ++
            "-" ++ std.fmt.bytesToHex(bytes[4..6], .lower) ++
            "-" ++ std.fmt.bytesToHex(bytes[6..8], .lower) ++
            "-" ++ std.fmt.bytesToHex(bytes[8..10], .lower) ++
            "-" ++ std.fmt.bytesToHex(bytes[10..], .lower);

        return result.*;
    }
};

test "returns a uuid v4" {
    var v4 = V4.init();
    const uuid = v4.generate();
    try testing.expect(uuid.len == 36);
}
