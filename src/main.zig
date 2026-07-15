const fire = @import("fire");
const std = @import("std");
const rl = @import("raylib");

// Main
const WIN_W: i32 = 600;
const WIN_H: i32 = 600;
const TITLE = "zig fire animation";
const FPS = 15; // 10 - 25 is ok

// Pixel
// PIXEL_SIZE: 10 - 40 is cool, so about 2% - 6% of the window size
const PIXEL_SIZE = rl.Vector2.init(20, 20);
// Max value for color value is 255 - PIXEL_SCRAMBLE_N
// Max value for color value is 0 + PIXEL_SCRAMBLE_N
const PIXEL_COLORS = [_]rl.Color{
    // Backgroun
    rl.Color.init(25, 25, 25, 255),
    rl.Color.init(25, 25, 25, 255), // Added twice for igger chance of being chosen
    rl.Color.init(50, 50, 50, 255),
    // Fire
    rl.Color.init(225, 150, 25, 255),
    rl.Color.init(225, 175, 50, 255),
    rl.Color.init(225, 200, 50, 255),
    rl.Color.init(225, 225, 75, 255),
    rl.Color.init(225, 225, 100, 255),
};
const PIXLE_COLOR_SHIFT_VAL: u8 = 20;
const PIXEL_ROW_N = WIN_W / PIXEL_SIZE.x;
const PIXEL_COL_N = WIN_H / PIXEL_SIZE.y;
const PIXEL_SCRAMBLE_N = 2;
const PIXEL_SCRAMBLE_AXISX_N = 20;

const Pixel = struct {
    pos: rl.Vector2,
    size: rl.Vector2,
    rect: rl.Rectangle,
    color: rl.Color,

    pub fn init(pos: rl.Vector2, size: rl.Vector2, color: rl.Color) Pixel {
        return Pixel{
            .pos = pos,
            .size = size,
            .rect = rl.Rectangle.init(pos.x, pos.y, size.x, size.y),
            .color = color
        };
    }
};

pub fn main() !void {
    rl.initWindow(WIN_W, WIN_H, TITLE);
    defer rl.closeWindow();

    rl.setTargetFPS(FPS);

    // Random
    var prng = std.Random.DefaultPrng.init(@as(u64, 1234)); // not random ):
    const random = prng.random();

    // Pixel array
    var pixelArray:[PIXEL_ROW_N][PIXEL_COL_N]Pixel = undefined;

    var frameCount: usize = 0;

    while (!rl.windowShouldClose()) {
        // const dt = rl.getFrameTime();

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        if (frameCount % PIXEL_SCRAMBLE_N == 0) {
            // Fill pixelArray
            for (0..PIXEL_ROW_N) |row| {
                for (0..PIXEL_COL_N) |col| {
                    // Get pixel color
                    const chosenColor = PIXEL_COLORS[random.uintAtMost(u8, PIXEL_COLORS.len - 1)];
                    var generatedColor: rl.Color = undefined;
                    generatedColor.r = random.intRangeAtMost(u8, chosenColor.r - PIXLE_COLOR_SHIFT_VAL, chosenColor.r + PIXLE_COLOR_SHIFT_VAL);
                    generatedColor.g = random.intRangeAtMost(u8, chosenColor.g - PIXLE_COLOR_SHIFT_VAL, chosenColor.g + PIXLE_COLOR_SHIFT_VAL);
                    generatedColor.b = random.intRangeAtMost(u8, chosenColor.b - PIXLE_COLOR_SHIFT_VAL, chosenColor.b + PIXLE_COLOR_SHIFT_VAL);
                    generatedColor.a = 255;

                    pixelArray[row][col] = Pixel.init(
                        rl.Vector2.init(@as(f32, @floatFromInt(row)) * PIXEL_SIZE.x, @as(f32, @floatFromInt(col)) * PIXEL_SIZE.y),
                        PIXEL_SIZE,
                        generatedColor,
                    );
                }
            }

            // Sort pixelArray items
            for (&pixelArray) |*row| {
                std.mem.sort(Pixel, row, {}, comptime struct {
                    fn lessThan(_: void, a: Pixel, b: Pixel) bool {
                        const aColorSum: u16 = @as(u16, a.color.r) + @as(u16, a.color.g) + @as(u16, a.color.b);
                        const bColorSum: u16 = @as(u16, b.color.r) + @as(u16, b.color.g) + @as(u16, b.color.b);
                        return aColorSum < bColorSum;
                    }
                }.lessThan);
            }
        }

        // Scramble pixelArray items in x axis
        for (0..PIXEL_ROW_N) |row| {
            for (0..PIXEL_SCRAMBLE_AXISX_N) |_| {
                const randomId = random.uintLessThan(u8, PIXEL_COL_N - 1);
                var tmp: Pixel = undefined;
                tmp = pixelArray[row][randomId];
                pixelArray[row][randomId] = pixelArray[randomId][randomId];
                pixelArray[randomId][randomId] = tmp;
            }
        }

        // Update pixel's position + render
        for (0..PIXEL_ROW_N) |row| {
            for (0..PIXEL_COL_N) |col| {
                pixelArray[row][col].rect.x = @as(f32, @floatFromInt(row)) * PIXEL_SIZE.x;
                pixelArray[row][col].rect.y = @as(f32, @floatFromInt(col)) * PIXEL_SIZE.y;

                rl.drawRectangleRec(pixelArray[row][col].rect, pixelArray[row][col].color);
            }
        }

        frameCount += 1;
    }
}