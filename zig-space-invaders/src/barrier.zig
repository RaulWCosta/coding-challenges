const rl = @import("raylib");

pub const Barrier = struct {
    xPos: i32,
    yPos: i32,
    format: [7][10]u8,

    pub fn init(x: i32, y: i32) Barrier {
        const format: [7][10]u8 = [_][10]u8{
            [_]u8{ ' ', 'x', 'x', 'x', 'x', 'x', 'x', 'x', 'x', ' ' },
            [_]u8{ 'x', 'x', 'x', 'x', 'x', 'x', 'x', 'x', 'x', 'x' },
            [_]u8{ 'x', 'x', 'x', 'x', 'x', 'x', 'x', 'x', 'x', 'x' },
            [_]u8{ 'x', 'x', 'x', 'x', 'x', 'x', 'x', 'x', 'x', 'x' },
            [_]u8{ 'x', 'x', 'x', 'x', 'x', 'x', 'x', 'x', 'x', 'x' },
            [_]u8{ 'x', 'x', 'x', ' ', ' ', ' ', ' ', 'x', 'x', 'x' },
            [_]u8{ 'x', 'x', ' ', ' ', ' ', ' ', ' ', ' ', 'x', 'x' },
        };

        return Barrier{
            .xPos = x,
            .yPos = y,
            .format = format,
        };
    }

    pub fn draw(self: Barrier) void {
        const width = 10;
        const height = 10;

        for (self.format, 0..) |row, i| {
            for (row, 0..) |cell, j| {
                if (cell == 'x') {
                    const _i: i32 = @intCast(i);
                    const _j: i32 = @intCast(j);
                    rl.drawRectangle(
                        self.xPos + _j * width,
                        self.yPos + _i * height,
                        width,
                        height,
                        .blue,
                    );
                }
            }
        }
    }

    pub fn collision(self: Barrier, x: i32, y: i32) bool {
        const width = 50;
        const height = 20;
        return (x >= self.xPos and x <= self.xPos + width) and (y >= self.yPos and y <= self.yPos + height);
    }
};
