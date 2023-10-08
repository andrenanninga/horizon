const std = @import("std");
const glfw = @import("mach-glfw");

pub fn main() !void {
    _ = glfw.init(.{});

    const window = glfw.Window.create(800, 600, "Horizon", null, null, .{}).?;
    defer window.destroy();

    while (!window.shouldClose()) {
        glfw.pollEvents();
        window.swapBuffers();
    }
}
