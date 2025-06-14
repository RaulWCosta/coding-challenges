const rl = @import("raylib");
const std = @import("std");
const BulletManager = @import("bullet.zig").BulletManager;
const Bullet = @import("bullet.zig").Bullet;
const utils = @import("utils.zig");

const Alien = struct {
    xPos: i32,
    yPos: i32,
    texture: rl.Texture2D,
    is_alive: bool = true,

    fn init(x: i32, y: i32, texture: rl.Texture2D) Alien {
        return Alien{
            .xPos = x,
            .yPos = y,
            .texture = texture,
        };
    }

    fn draw(self: Alien) void {
        rl.drawTexture(
            self.texture,
            self.xPos,
            self.yPos,
            .white,
        );
    }

    fn move_side(self: *Alien, speed: i8, direction: i8) void {
        self.xPos += speed * direction;
    }

    fn move_down(self: *Alien, y_gap: i32) void {
        self.yPos += y_gap;
    }

    fn collision(self: *Alien, bullet: *Bullet) bool {
        if (!bullet.enabled) return false; // No collision if the bullet is not enabled
        const alien_rect = rl.Rectangle{
            .x = @floatFromInt(self.xPos),
            .y = @floatFromInt(self.yPos),
            .width = @floatFromInt(self.texture.width),
            .height = @floatFromInt(self.texture.height),
        };
        return rl.checkCollisionRecs(alien_rect, bullet.object);
    }

    fn shoot(self: *Alien, bullets_mng: *BulletManager) void {
        const _width: f32 = @floatFromInt(self.texture.width);
        const _height: f32 = @floatFromInt(self.texture.height);

        const bullet_x: i32 = @intFromFloat(_width / 2);
        const bullet_y: i32 = @intFromFloat(_height / 2);

        bullets_mng.enemy_shoot(bullet_x + self.xPos, bullet_y + self.yPos);
    }
};

const AlienRow = struct {
    aliens: [11]Alien,
    texture: rl.Texture2D,
    aliens_count: usize = 11,
    down_mov_speed: i8 = 20,
    mov_speed: i8 = 10,
    curr_direction: i8 = 1, // 1 for right, -1 for left
    screen_bottom: i32,

    fn init(xPos: i32, yPos: i32, gapX: i32, texture_file: [:0]const u8) rl.RaylibError!AlienRow {
        var aliens: [11]Alien = undefined;
        const texture = try rl.loadTexture(texture_file);

        for (&aliens, 0..) |*alien, i| {
            const _i: i32 = @intCast(i);
            alien.* = Alien.init(xPos + _i * gapX, yPos, texture);
        }
        return AlienRow{
            .aliens = aliens,
            .texture = texture,
            .screen_bottom = utils.getScreenBottom(),
        };
    }

    fn deinit(self: AlienRow) void {
        rl.unloadTexture(self.texture);
    }

    fn isAlive(self: AlienRow) bool {
        return self.aliens_count > 0;
    }

    fn draw(self: AlienRow) void {
        for (self.aliens) |alien| {
            if (alien.is_alive) {
                alien.draw();
            }
        }
    }

    fn move(self: *AlienRow) bool {
        var is_move_down: bool = false;

        for (self.aliens) |alien| {
            if (alien.xPos <= 60 or alien.xPos >= (rl.getScreenWidth() - 130)) {
                // If any alien reaches the bottom, the game is over
                is_move_down = true;
            }
        }

        if (is_move_down) {
            for (&self.aliens) |*alien| {
                alien.move_down(self.down_mov_speed);
                if (alien.yPos >= (self.screen_bottom)) {
                    return true; // Aliens reached the bottom
                }
            }
            // Change direction
            self.curr_direction *= -1;

            // update the movement speed
            self.mov_speed += 2;
        }
        // Move all aliens in the row by the given speed
        for (&self.aliens) |*alien| {
            alien.move_side(self.mov_speed, self.curr_direction);
        }
        return false;
    }

    fn collision(self: *AlienRow, bullet: *Bullet) bool {
        if (!bullet.enabled) return false;
        for (&self.aliens, 0..) |*alien, i| {
            if (!alien.is_alive) continue; // Skip dead aliens
            if (alien.collision(bullet)) {
                bullet.enabled = false;
                self.aliens_count -= 1;
                self.aliens[i].is_alive = false;
                return true;
            }
        }
        return false;
    }
};

pub const AlienSwarm = struct {
    rows: [5]AlienRow,

    curr_row_move: usize = 4,
    move_ticks: u8 = 9, // Used to control the movement speed
    alien_shoot_probability: f16 = 3.0,
    alien_shoot_prob_delta: f16 = 0.3,

    bullets_mng: *BulletManager,

    pub fn init(bullets_mng: *BulletManager) rl.RaylibError!AlienSwarm {
        const startX = 80;
        const startY = 80;
        const gapY = 60;
        const gapX = 70;

        var rows: [5]AlienRow = undefined;
        rows[0] = try AlienRow.init(startX, startY, gapX, "assets/red.png");
        rows[1] = try AlienRow.init(startX, startY + (1 * gapY), gapX, "assets/red.png");
        rows[2] = try AlienRow.init(startX, startY + (2 * gapY), gapX, "assets/yellow.png");
        rows[3] = try AlienRow.init(startX, startY + (3 * gapY), gapX, "assets/yellow.png");
        rows[4] = try AlienRow.init(startX, startY + (4 * gapY), gapX, "assets/green.png");

        return AlienSwarm{
            .rows = rows,
            .bullets_mng = bullets_mng,
        };
    }

    pub fn deinit(self: AlienSwarm) void {
        for (self.rows) |row| {
            row.deinit();
        }
    }

    fn allAliensDead(self: *AlienSwarm) bool {
        for (self.rows) |row| {
            if (row.isAlive()) {
                return false; // At least one row is still alive
            }
        }
        return true; // All rows are dead
    }

    fn update_curr_row_move(self: *AlienSwarm) void {
        // Update the current row to move based on the movement speed
        while (true) {
            // std.debug.print("Current row to move: {}\n", .{self.curr_row_move});
            // fix out of bounds
            if (self.curr_row_move == 0) {
                self.curr_row_move = 5;
            }

            self.curr_row_move -= 1;

            if (self.rows[self.curr_row_move].isAlive()) {
                break;
            }
        }
    }

    pub fn update(self: *AlienSwarm) bool {
        if (self.allAliensDead()) {
            std.debug.print("All aliens are dead. Resetting current row to move.\n", .{});
            return true;
        }

        const reached_bottom = self.move();
        if (reached_bottom) {
            std.debug.print("Aliens reached the bottom. Game over!\n", .{});
            return true; // Game over condition
        }

        self.draw();
        self.collision();
        self.shoot();
        return false;
    }

    fn shoot(self: *AlienSwarm) void {
        const rand = std.crypto.random;

        const shoot_prob: u8 = @intFromFloat(@floor(self.alien_shoot_probability));
        for (&self.rows) |*row| {
            if (row.isAlive() and rand.int(u8) < shoot_prob) {
                const aliens_count: u8 = @intCast(row.aliens_count);
                const random_index = rand.int(u8) % aliens_count;
                const alien = &row.aliens[random_index];
                if (alien.is_alive) {
                    alien.shoot(self.bullets_mng);
                }
            }
        }
    }

    fn move(self: *AlienSwarm) bool {
        if (self.move_ticks == 0) {
            const reached_bottom = self.rows[self.curr_row_move].move();
            self.update_curr_row_move();
            self.move_ticks = 9; // Reset the move ticks
            return reached_bottom;
        } else {
            self.move_ticks -= 1;
        }
        return false;
    }

    fn draw(self: AlienSwarm) void {
        for (self.rows) |row| {
            row.draw();
        }
    }

    fn collision(self: *AlienSwarm) void {
        const player_bullet = &self.bullets_mng.player_bullet;
        for (&self.rows) |*row| {
            if (row.collision(player_bullet)) {
                self.alien_shoot_probability += self.alien_shoot_prob_delta;
                return;
            }
        }
    }
};
