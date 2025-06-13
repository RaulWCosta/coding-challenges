const rl = @import("raylib");
const std = @import("std");
const BulletManager = @import("bullet.zig").BulletManager;
const Bullet = @import("bullet.zig").Bullet;

const SPEED_SHIP: i32 = 10;

pub const Spaceship = struct {
    x_pos: i32,
    y_pos: i32,
    width: i32,
    height: i32,
    lifes: u8 = 30,
    spaceshipTexture: rl.Texture2D,
    shoot_cooldown: i32,
    bullets_mng: *BulletManager,

    pub fn init(bullets_mng: *BulletManager) rl.RaylibError!Spaceship {
        const spaceshipTexture = try rl.loadTexture("assets/player.png");
        const screen_height = rl.getScreenHeight();
        const y_pos = @as(i32, @intFromFloat(@as(f32, @floatFromInt(screen_height)) * 0.9));

        return Spaceship{
            .x_pos = 400,
            .y_pos = y_pos,
            .width = 60,
            .height = 30,
            .spaceshipTexture = spaceshipTexture,
            .shoot_cooldown = 0,
            .bullets_mng = bullets_mng,
        };
    }

    pub fn deinit(self: *Spaceship) void {
        rl.unloadTexture(self.spaceshipTexture); // Unload spaceship texture
    }

    pub fn update(self: *Spaceship) void {
        self.move();
        self.draw();
        self.collision(&self.bullets_mng.enemies_bullets);

        // Reduce cooldown if it's active
        if (self.shoot_cooldown > 0) {
            self.shoot_cooldown -= 1;
        }

        if (rl.isKeyPressed(rl.KeyboardKey.space)) {
            self.shoot();
        }
    }

    fn collision(self: *Spaceship, bullets: *[10]Bullet) void {
        const spaceship_rect = rl.Rectangle{
            .x = @floatFromInt(self.x_pos),
            .y = @floatFromInt(self.y_pos),
            .width = @floatFromInt(self.width),
            .height = @floatFromInt(self.height),
        };
        for (bullets, 0..) |b, i| {
            if (b.enabled and rl.checkCollisionRecs(spaceship_rect, b.object)) {
                self.lifes -= 1;
                if (self.lifes == 0) {
                    // Handle game over logic here
                    std.debug.print("Game Over! Spaceship destroyed.", .{});
                    bullets[i].enabled = false;
                }
                break;
            }
        }
    }

    fn move(self: *Spaceship) void {
        if (rl.isKeyDown(rl.KeyboardKey.left)) {
            if (self.x_pos > 60) {
                self.x_pos -= SPEED_SHIP;
            }
        } else if (rl.isKeyDown(rl.KeyboardKey.right)) {
            if (self.x_pos < rl.getScreenWidth() - 130) {
                self.x_pos += SPEED_SHIP;
            }
        }
    }

    fn draw(self: *const Spaceship) void {
        // Draw the spaceship texture
        rl.drawTexture(
            self.spaceshipTexture,
            self.x_pos,
            self.y_pos,
            rl.Color.white,
        );
    }

    pub fn canShoot(self: *const Spaceship) bool {
        return self.shoot_cooldown <= 0;
    }

    pub fn shoot(self: *Spaceship) void {
        if (!self.canShoot()) return;

        // Create a bullet at the center-top of the spaceship
        const bullet_x = self.x_pos + 30; // Adjust based on spaceship's real width
        const bullet_y = self.y_pos - 10;

        self.bullets_mng.player_shoot(bullet_x, bullet_y);

        // Set cooldown to prevent rapid firing
        self.shoot_cooldown = 15; // Adjust this value for desired fire rate
    }
};
