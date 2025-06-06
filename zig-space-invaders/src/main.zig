const std = @import("std");
const rl = @import("raylib");
const Barrier = @import("barrier.zig").Barrier;

fn drawTopMenu(score: [:0]const u8) void {
    // Draw top menu
    rl.drawRectangle(0, 0, rl.getScreenWidth(), 40, .black);
    rl.drawText("SCORE", 80, 10, 20, .white);

    rl.drawText(score, 160, 10, 20, .green);

    std.debug.print("", .{});

    const half = @divFloor(rl.getScreenWidth(), 2);

    rl.drawText("LIVES", half + 30, 10, 20, .white);

    rl.drawRectangle(half + 110, 10, 20, 20, .green);
    rl.drawRectangle(half + 140, 10, 20, 20, .green);
    rl.drawRectangle(half + 170, 10, 20, 20, .green);
}

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 800;
    const screenHeight = 450;
    const speed = 8;

    // const config_flags = rl.ConfigFlags{ .window_resizable = true };

    // rl.setConfigFlags(config_flags);
    rl.initWindow(
        screenWidth,
        screenHeight,
        "raylib-zig [core] example - basic window",
    );
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    var xPosition: i32 = 400;
    const spaceshipTexture = try rl.loadTexture("assets/player.png");
    defer rl.unloadTexture(spaceshipTexture); // Unload spaceship texture
    const barriers: [4]Barrier = .{
        Barrier.init(50, 300),
        Barrier.init(250, 300),
        Barrier.init(450, 300),
        Barrier.init(650, 300),
    };

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        // draw top menu
        drawTopMenu("000000");

        if (rl.isKeyDown(rl.KeyboardKey.left)) {
            if (xPosition > 60) {
                xPosition -= speed;
            }
        } else if (rl.isKeyDown(rl.KeyboardKey.right)) {
            if (xPosition < screenWidth - 120) {
                xPosition += speed;
            }
        }

        // Draw Barrier
        for (barriers) |b| {
            b.draw();
        }

        // draw spaceship
        rl.drawTexture(spaceshipTexture, xPosition, 400, .white);

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.gray);

        // rl.drawText("Congrats! You created your first window!", 190, 200, 20, .light_gray);
        //----------------------------------------------------------------------------------
    }
}
