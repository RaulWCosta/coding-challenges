const rl = @import("raylib");
const std = @import("std");

const Alien = struct {
    xPos: i32,
    yPos: i32,
    texture: rl.Texture2D,

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

    // fn isAlive() bool {
    //     return true;
    // }
};

const AlienRow = struct {
    aliens: [11]Alien,
    texture: rl.Texture2D,
    aliens_count: usize = 11,
    down_mov_speed: i8 = 20,
    mov_speed: i8 = 10,
    curr_direction: i8 = 1, // 1 for right, -1 for left

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
            // if (alien.isAlive()) {
            alien.draw();
            // }
        }
    }

    fn move(self: *AlienRow) void {
        var is_move_down: bool = false;

        for (self.aliens) |alien| {
            if (alien.xPos <= 60 or alien.xPos >= (rl.getScreenWidth() - 130)) {
                // If any alien reaches the bottom, the game is over
                is_move_down = true;
            }
        }

        if (is_move_down) {
            for (&self.aliens) |*alien| {
                // Move all aliens down by the down_mov_speed
                alien.move_down(self.down_mov_speed);
            }
            // Change direction
            self.curr_direction *= -1;

            // update the movement speed
            self.mov_speed += 1;
        }
        // Move all aliens in the row by the given speed
        for (&self.aliens) |*alien| {
            alien.move_side(self.mov_speed, self.curr_direction);
        }
    }

    // fn move_down(self: AlienRow) void {
    //     // Move all aliens in the row down by a fixed amount
    //     for (self.aliens) |*alien| {
    //         alien.yPos += self.gapY;
    //     }
    // }
};

pub const AlienSwarm = struct {
    rows: [5]AlienRow,

    curr_row_move: usize = 4,
    move_ticks: u8 = 9, // Used to control the movement speed

    pub fn init() rl.RaylibError!AlienSwarm {
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
        };
    }

    pub fn deinit(self: AlienSwarm) void {
        for (self.rows) |row| {
            row.deinit();
        }
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

    pub fn move(self: *AlienSwarm) void {
        if (self.move_ticks == 0) {
            self.rows[self.curr_row_move].move();
            self.update_curr_row_move();
            self.move_ticks = 9; // Reset the move ticks
        } else {
            self.move_ticks -= 1;
        }
    }

    pub fn draw(self: AlienSwarm) void {
        for (self.rows) |row| {
            row.draw();
        }
    }
};
