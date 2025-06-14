const std = @import("std");
const rl = @import("raylib");
const BarrierManager = @import("barrier.zig").BarrierManager;
const alien = @import("alien.zig");
const Spaceship = @import("spaceship.zig").Spaceship;
const BulletManager = @import("bullet.zig").BulletManager;

const SCREEN_WIDTH: i32 = 1120;
const SCREEN_HEIGHT: i32 = 800;

fn drawTopMenu(score: u32, lives: u8) !void {
    std.debug.print("Score: {}, Lives: {}", .{ score, lives });

    // const print_score = std.fmt.format("{:06}", .{score});
    const menu_height: i32 = @divFloor(SCREEN_HEIGHT, 11);
    const menu_width: i32 = SCREEN_WIDTH;
    const font_size: i32 = @divFloor(menu_height, 2);

    // Draw top menu
    rl.drawRectangle(0, 0, menu_width, menu_height, .black);
    rl.drawText(
        "SCORE",
        @divFloor(menu_width, 5),
        @divFloor(menu_height, 2) - 10,
        font_size,
        .white,
    );

    var buf: [7]u8 = undefined;
    rl.drawText(
        try std.fmt.bufPrintZ(&buf, "{:0>6}", .{score}),
        @divFloor(menu_width, 4) + 80,
        @divFloor(menu_height, 2) - 10,
        font_size,
        .green,
    );

    const half = @divFloor(menu_width, 2);

    rl.drawText(
        "LIVES",
        half + 30,
        @divFloor(menu_height, 2) - 10,
        font_size,
        .white,
    );

    const x_pos_first_life: i32 = half + 160;

    for (0..lives) |i| {
        const _i: i32 = @intCast(i);
        rl.drawRectangle(
            x_pos_first_life + _i * 40,
            @divFloor(menu_height, 2) - 6,
            25,
            25,
            .green,
        );
    }
}

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------

    // const config_flags = rl.ConfigFlags{ .window_resizable = true };

    // rl.setConfigFlags(config_flags);
    rl.initWindow(
        SCREEN_WIDTH,
        SCREEN_HEIGHT,
        "raylib-zig [core] example - basic window",
    );
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    var bullets_mng = BulletManager.init();

    // Barriers
    var barriers_mng = BarrierManager.init(&bullets_mng);

    // Aliens
    var alien_swarm = try alien.AlienSwarm.init(&bullets_mng);
    defer alien_swarm.deinit(); // Cleanup aliens

    var spaceship = try Spaceship.init(&bullets_mng);
    defer spaceship.deinit(); // Cleanup spaceship
    var current_player_score: u32 = 0;

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key

        // Begin drawing
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.gray);

        // Draw top menu
        try drawTopMenu(current_player_score, spaceship.lifes);

        // Update game entities
        const player_dead = spaceship.update();
        const aliens_update = alien_swarm.update();
        current_player_score = aliens_update.player_score;

        if (player_dead or aliens_update.is_game_over) {
            break;
        }

        bullets_mng.update();
        barriers_mng.update();
    }

    std.debug.print("Game over!", .{});
    // std.time.sleep(std.time.ns_per_s * 2); // Sleep for a second before exiting
    rl.closeWindow(); // Close window and OpenGL context
}
