const rl = @import("raylib");

pub fn getScreenBottom() i32 {
    const _tmp: f32 = @floatFromInt(rl.getScreenHeight());
    return @intFromFloat(@floor(_tmp * 0.7));
}
