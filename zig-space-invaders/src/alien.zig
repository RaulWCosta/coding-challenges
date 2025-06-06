const rl = @import("raylib");

const Alien = struct {
    xPos: i32,
    yPos: i32,
    texture: rl.Texture2D,

    fn init(x: i32, y: i32, texture_path: []u8) Alien {
        return Alien{
            .xPos = x,
            .yPos = y,
            .texture = try rl.loadTexture(texture_path),
        };
    }

    fn deinit(self: Alien) void {
        // Cleanup if needed
        rl.unloadTexture(self.texture); // Unload alien texture
    }

    fn draw(self: Alien) void {
        rl.drawTexture(
            self.texture,
            self.xPos,
            self.yPos,
            .white,
        );
    }
};

const AlienRow = struct {
    aliens: [11]Alien,

    fn init(xPos: i32, yPos: i32, gapX: i32, texture_file: []u8) AlienRow {
        const aliens: [11]Alien = undefined;
        for (aliens, 0..) |*alien, i| {
            alien.* = Alien.init(xPos + i * gapX, yPos, texture_file);
        }
        return AlienRow{
            .aliens = aliens,
        };
    }

    fn deinit(self: AlienRow) void {
        for (self.aliens) |alien| {
            alien.deinit();
        }
    }

    fn draw(self: AlienRow) void {
        for (self.aliens) |alien| {
            alien.draw();
        }
    }
};

const AlienSwarm = struct {
    rows: [5]AlienRow,

    fn init(texture_file: []u8) AlienSwarm {
        const startX = 100;
        const startY = 50;
        const gapY = 30;
        const gapX = 20;

        const rows: [5]AlienRow = undefined;
        for (rows, 0..) |*row, i| {
            row.* = AlienRow.init(
                startX,
                startY + i * gapY,
                gapX,
                texture_file,
            );
        }
        return AlienSwarm{
            .rows = rows,
        };
    }

    fn deinit(self: AlienSwarm) void {
        for (self.rows) |row| {
            row.deinit();
        }
    }

    fn draw(self: AlienSwarm) void {
        for (self.rows) |row| {
            row.draw();
        }
    }
};
