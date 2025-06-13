const rl = @import("raylib");
const BulletManager = @import("bullet.zig").BulletManager;
const Bullet = @import("bullet.zig").Bullet;

pub const Barrier = struct {
    xPos: i32,
    yPos: i32,
    bricks: [7][10]?rl.Rectangle,
    width: u8,
    height: u8,

    pub fn init(x: i32, y: i32) Barrier {
        const brick_width: u8 = 10;
        const brick_height: u8 = 10;

        const format: [7][10]u8 = [_][10]u8{
            [_]u8{ ' ', 'x', 'x', 'x', 'x', 'x', 'x', 'x', 'x', ' ' },
            [_]u8{ 'x', 'x', 'x', 'x', 'x', 'x', 'x', 'x', 'x', 'x' },
            [_]u8{ 'x', 'x', 'x', 'x', 'x', 'x', 'x', 'x', 'x', 'x' },
            [_]u8{ 'x', 'x', 'x', 'x', 'x', 'x', 'x', 'x', 'x', 'x' },
            [_]u8{ 'x', 'x', 'x', 'x', 'x', 'x', 'x', 'x', 'x', 'x' },
            [_]u8{ 'x', 'x', 'x', ' ', ' ', ' ', ' ', 'x', 'x', 'x' },
            [_]u8{ 'x', 'x', ' ', ' ', ' ', ' ', ' ', ' ', 'x', 'x' },
        };

        var bricks: [7][10]?rl.Rectangle = undefined;
        for (format, 0..) |row, i| {
            for (row, 0..) |cell, j| {
                const _i: i32 = @intCast(i);
                const _j: i32 = @intCast(j);
                if (cell == 'x') {
                    bricks[i][j] = rl.Rectangle{
                        .x = @floatFromInt(x + _j * brick_width),
                        .y = @floatFromInt(y + _i * brick_height),
                        .width = @floatFromInt(brick_width),
                        .height = @floatFromInt(brick_height),
                    };
                } else {
                    bricks[i][j] = null;
                }
            }
        }

        return Barrier{
            .xPos = x,
            .yPos = y,
            .bricks = bricks,
            .width = 10 * brick_width,
            .height = 7 * brick_height,
        };
    }

    pub fn draw(self: Barrier) void {
        for (self.bricks) |row| {
            for (row) |brick| {
                if (brick) |b| {
                    rl.drawRectangleRec(b, rl.Color.blue);
                }
            }
        }
    }

    pub fn collision(self: *Barrier, bullet: *Bullet) void {
        if (bullet.enabled == false) {
            return;
        }

        const bullet_x_pos: i32 = @intFromFloat(bullet.object.x);
        const bullet_y_pos: i32 = @intFromFloat(bullet.object.y);

        if (!(bullet_x_pos >= self.xPos and bullet_x_pos <= self.xPos + self.width) or !(bullet_y_pos >= self.yPos and bullet_y_pos <= self.yPos + self.height)) return;

        for (self.bricks, 0..) |row, i| {
            for (row, 0..) |brick, j| {
                if (brick) |b| {
                    if (rl.checkCollisionRecs(
                        bullet.object,
                        b,
                    )) {
                        bullet.enabled = false; // Disable the bullet on collision
                        self.bricks[i][j] = null; // Remove the brick on collision
                        return;
                    }
                }
            }
        }
    }
};

pub const BarrierManager = struct {
    barriers: [5]Barrier,
    bullets_mng: *BulletManager,

    pub fn init(bullets_mng: *BulletManager) BarrierManager {
        const _tmp: f32 = @floatFromInt(rl.getScreenHeight());
        const barrier_y_start: i32 = @intFromFloat(@floor(_tmp * 0.75));
        const barrier_x_gap: i32 = @divFloor(rl.getScreenWidth(), 5);
        const barrier_x_start: i32 = 60;

        return BarrierManager{
            .barriers = [_]Barrier{
                Barrier.init(barrier_x_start, barrier_y_start),
                Barrier.init(barrier_x_start + barrier_x_gap, barrier_y_start),
                Barrier.init(barrier_x_start + 2 * barrier_x_gap, barrier_y_start),
                Barrier.init(barrier_x_start + 3 * barrier_x_gap, barrier_y_start),
                Barrier.init(barrier_x_start + 4 * barrier_x_gap, barrier_y_start),
            },
            .bullets_mng = bullets_mng,
        };
    }

    pub fn update(self: *BarrierManager) void {
        self.collision();
        self.draw();
    }

    fn draw(self: *const BarrierManager) void {
        for (self.barriers) |barrier| {
            barrier.draw();
        }
    }

    fn collision(self: *BarrierManager) void {
        for (&self.barriers) |*barrier| {
            if (self.bullets_mng.player_bullet.enabled) {
                barrier.collision(&self.bullets_mng.player_bullet);
            }
            barrier.collision(&self.bullets_mng.player_bullet);

            for (&self.bullets_mng.enemies_bullets) |*bullet| {
                if (!bullet.enabled) continue;
                barrier.collision(bullet);
            }
        }
    }
};
