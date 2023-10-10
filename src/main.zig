const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");

fn glGetProcAddress(p: glfw.GLProc, proc: [:0]const u8) ?gl.FunctionPointer {
    _ = p;
    return glfw.getProcAddress(proc);
}

/// Default GLFW error handling callback
fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

const Mesh = struct {
    vertices: [32]f32 = [1]f32{32} ** 32,
    indices: [32]u32 = [1]u32{32} ** 32,

    vertexCount: i32 = 0,
    indexCount: i32 = 0,

    vao: u32 = undefined,
    vbo: u32 = undefined,
    ibo: u32 = undefined,

    const Self = @This();

    fn create(self: *Self) void {
        gl.genVertexArrays(1, &self.vao);
        gl.genBuffers(1, &self.vbo);
        gl.genBuffers(1, &self.ibo);

        gl.bindVertexArray(self.vao);

        gl.bindBuffer(gl.ARRAY_BUFFER, self.vbo);
        gl.bufferData(
            gl.ARRAY_BUFFER,
            self.vertexCount * @sizeOf(f32),
            self.vertices[0..].ptr,
            gl.STATIC_DRAW,
        );

        gl.vertexAttribPointer(
            0,
            3,
            gl.FLOAT,
            gl.FALSE,
            3 * @sizeOf(f32),
            null,
        );
        gl.enableVertexAttribArray(0);

        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.ibo);
        gl.bufferData(
            gl.ELEMENT_ARRAY_BUFFER,
            self.indexCount * @sizeOf(u32),
            self.indices[0..].ptr,
            gl.STATIC_DRAW,
        );

        gl.bindBuffer(gl.ARRAY_BUFFER, 0);
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);
        gl.bindVertexArray(0);
    }

    fn bind(self: Self) void {
        gl.bindVertexArray(self.vao);
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.ibo);
        gl.drawElements(gl.TRIANGLES, self.indexCount, gl.UNSIGNED_INT, null);
    }

    fn deinit(self: Self) void {
        gl.deleteVertexArrays(1, &self.vao);
        gl.deleteBuffers(1, &self.vbo);
        gl.deleteBuffers(1, &self.ibo);
    }
};

const Shader = struct {
    program: u32 = 0,

    vertSource: []const u8,
    fragSource: []const u8,

    const Self = @This();

    fn compile(self: *Self) void {
        const vertShader = gl.createShader(gl.VERTEX_SHADER);
        gl.shaderSource(vertShader, 1, &self.vertSource.ptr, null);
        gl.compileShader(vertShader);

        const fragShader = gl.createShader(gl.FRAGMENT_SHADER);
        gl.shaderSource(fragShader, 1, &self.fragSource.ptr, null);
        gl.compileShader(fragShader);

        self.program = gl.createProgram();
        gl.attachShader(self.program, vertShader);
        gl.attachShader(self.program, fragShader);
        gl.linkProgram(self.program);

        gl.deleteShader(vertShader);
        gl.deleteShader(fragShader);
    }

    fn bind(self: Self) void {
        gl.useProgram(self.program);
    }

    fn deinit(self: Self) void {
        gl.deleteProgram(self.program);
    }
};

pub fn main() !void {
    glfw.setErrorCallback(errorCallback);
    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    // Create our window
    const window = glfw.Window.create(
        640,
        480,
        "Horizon",
        null,
        null,
        .{
            .context_version_major = 3,
            .context_version_minor = 3,
            .opengl_forward_compat = true,
            .opengl_profile = glfw.Window.Hints.OpenGLProfile.opengl_core_profile,
        },
    ) orelse {
        std.log.err("failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };

    defer window.destroy();

    glfw.makeContextCurrent(window);

    const proc: glfw.GLProc = undefined;
    try gl.load(proc, glGetProcAddress);

    // Data

    const vertices = [_]f32{
        -0.5, -0.5, 0,
        0.5,  -0.5, 0,
        0,    0.5,  0,
    };

    const indices = [_]u32{
        0, 1, 2,
    };

    var mesh = Mesh{};
    @memcpy(mesh.vertices[0..vertices.len], vertices[0..]);
    mesh.vertexCount = vertices.len;

    @memcpy(mesh.indices[0..indices.len], indices[0..]);
    mesh.indexCount = indices.len;

    mesh.create();

    // Shader
    var shader = Shader{
        .vertSource = @embedFile("vert.glsl"),
        .fragSource = @embedFile("frag.glsl"),
    };
    shader.compile();
    defer shader.deinit();

    // Wait for the user to close the window.
    while (!window.shouldClose()) {
        window.swapBuffers();

        gl.clearColor(1, 0, 0, 1);
        gl.clear(gl.COLOR_BUFFER_BIT);

        shader.bind();

        mesh.bind();

        glfw.pollEvents();
    }
}
