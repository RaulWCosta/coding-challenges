const rl = @import("raylib");
const std = @import("std");

pub const Bullet = struct {
    speed: i8,
    direction: i8 = -1, // -1 for up, 1 for down
    object: rl.Rectangle,
    enabled: bool,

    pub fn init(x: i32, y: i32, direction: i8, speed: i8, enabled: bool) Bullet {
        return Bullet{
            .speed = speed,
            .direction = direction,
            .object = rl.Rectangle{
                .x = @floatFromInt(x),
                .y = @floatFromInt(y),
                .width = 5,
                .height = 20,
            },
            .enabled = enabled,
        };
    }

    pub fn move(self: *Bullet) void {
        if (!self.enabled) return;
        self.object.y += @floatFromInt(self.speed * self.direction);

        if (self.isOutOfBounds()) {
            self.enabled = false; // Disable bullet if out of bounds
        }
    }

    pub fn draw(self: *const Bullet) void {
        if (!self.enabled) return;
        rl.drawRectangleRec(self.object, rl.Color.red);
    }

    pub fn isOutOfBounds(self: *const Bullet) bool {
        const screen_height: f32 = @floatFromInt(rl.getScreenHeight());
        return (self.object.y < (screen_height / 10)) or (self.object.y > screen_height);
    }
};

pub const BulletManager = struct {
    player_bullet: Bullet,
    enemies_bullets: [10]Bullet,

    pub fn init() BulletManager {
        var bullets = [_]Bullet{undefined} ** 10; // Preallocate space for enemy bullets
        for (&bullets) |*bullet| {
            bullet.* = Bullet.init(
                0,
                0,
                1,
                10,
                false,
            ); // Initialize all enemy bullets as disabled
        }

        return BulletManager{
            .player_bullet = Bullet.init(
                0,
                0,
                -1,
                10,
                false,
            ),
            .enemies_bullets = bullets,
        };
    }

    pub fn player_shoot(self: *BulletManager, x: i32, y: i32) void {
        if (self.player_bullet.enabled) return; // Only one player bullet at a time
        self.player_bullet = Bullet.init(
            x,
            y,
            -1,
            10,
            true,
        );
    }

    pub fn enemy_shoot(self: *BulletManager, x: i32, y: i32) void {
        for (self.enemies_bullets, 0..) |bullet, i| {
            if (!bullet.enabled) {
                self.enemies_bullets[i] = Bullet.init(
                    x,
                    y,
                    1,
                    10,
                    true,
                );
                break;
            }
        }
    }

    pub fn update(self: *BulletManager) void {
        // Move bullets
        self.player_bullet.move();
        for (&self.enemies_bullets) |*bullet| {
            bullet.move();
        }

        self.draw();
    }

    fn draw(self: *const BulletManager) void {
        // Draw player bullet
        if (self.player_bullet.enabled) {
            self.player_bullet.draw();
        }

        // Draw enemy bullets
        for (self.enemies_bullets) |bullet| {
            if (!bullet.enabled) continue;
            bullet.draw();
        }
    }
};
