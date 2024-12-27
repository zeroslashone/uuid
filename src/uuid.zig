pub const UUID = struct {
    pub const V1 = @import("uuid/v1.zig").V1;
    pub const V4 = @import("uuid/v4.zig").V4;
    pub const V7 = @import("uuid/v7.zig").V7;
};

test {
    _ = UUID.V1;
    _ = UUID.V4;
    _ = UUID.V7;
}
