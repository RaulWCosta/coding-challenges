const rl = @import("raylib");
const std = @import("std");

pub const Bullet = struct {
    x_pos: i32,
    y_pos: i32,
    speed: i32,
    direction: i8 = -1, // -1 for up, 1 for down
    object: rl.Rectangle,
    enabled: bool,

    pub fn init(x: i32, y: i32, direction: i8, enabled: bool) Bullet {
        return Bullet{
            .x_pos = x,
            .y_pos = y,
            .speed = 15,
            .direction = direction,
            .object = rl.Rectangle{
                .x = @floatFromInt(x),
                .y = @floatFromInt(y),
                .width = 5,
                .height = 10,
            },
            .enabled = enabled,
        };
    }

    pub fn move(self: *Bullet) void {
        if (!self.enabled) return;
        self.y_pos += self.speed * self.direction;
        self.object.y = @floatFromInt(self.y_pos);
    }

    pub fn draw(self: *const Bullet) void {
        if (!self.enabled) return;
        rl.drawRectangleRec(self.object, rl.Color.red);
    }

    pub fn isOutOfBounds(self: *const Bullet) bool {
        const screen_height = rl.getScreenHeight();
        return (self.y_pos < 0) or (self.y_pos > screen_height);
    }
};

pub const BulletManager = struct {
    player_bullet: Bullet,
    enemies_bullets: std.ArrayList(Bullet),

    pub fn init(allocator: std.mem.Allocator) !BulletManager {
        return BulletManager{
            .player_bullet = Bullet.init(0, 0, 0, false),
            .enemies_bullets = try std.ArrayList(Bullet).initCapacity(allocator, 10),
        };
    }

    pub fn deinit(self: *BulletManager) void {
        self.enemies_bullets.deinit();
    }

    pub fn add(self: *BulletManager, bullet: Bullet) !void {
        try self.enemies_bullets.append(bullet);
    }

    pub fn shoot_player(self: *BulletManager, x: i32, y: i32) void {
        if (self.player_bullet.enabled) return; // Only one player bullet at a time
        self.player_bullet = Bullet.init(x, y, -1, true);
    }

    pub fn update(self: *BulletManager) void {
        // Move player bullet
        self.player_bullet.move();
        if (self.player_bullet.isOutOfBounds()) {
            self.player_bullet.enabled = false;
        }

        // Move all enemy bullets
        var i: usize = 0;
        while (i < self.enemies_bullets.items.len) {
            var bullet = &self.enemies_bullets.items[i];
            bullet.move();

            if (bullet.isOutOfBounds()) {
                _ = self.enemies_bullets.swapRemove(i);
            } else {
                i += 1;
            }
        }
        self.draw();
    }

    fn draw(self: *const BulletManager) void {
        // Draw player bullet
        if (self.player_bullet.enabled) {
            self.player_bullet.draw();
        }

        // Draw enemy bullets
        for (self.enemies_bullets.items) |bullet| {
            if (!bullet.enabled) continue;
            bullet.draw();
        }
    }
};
