const std = @import("std");
const gl = @import("gl");
const glfw = @import("mach-glfw");

const Allocator = std.mem.Allocator;

pub const Engine = struct {
    window: ?glfw.Window = null,

    const Self = @This();

    fn glGetProcAddress(p: glfw.GLProc, proc: [:0]const u8) ?gl.FunctionPointer {
        _ = p;
        return glfw.getProcAddress(proc);
    }

    fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
        std.log.err("glfw: {}: {s}\n", .{ error_code, description });
    }

    pub fn init(self: *Self) !void {
        glfw.setErrorCallback(errorCallback);

        if (!glfw.init(.{})) {
            std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
            std.process.exit(1);
        }

        // Create our window
        self.window = glfw.Window.create(
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

        glfw.makeContextCurrent(self.window);

        const proc: glfw.GLProc = undefined;
        try gl.load(proc, glGetProcAddress);
    }

    pub fn deinit(self: *Self) void {
        if (self.window) |window| {
            window.destroy();
        }

        glfw.terminate();
    }

    pub fn isRunning(self: *Self) bool {
        self.window.?.swapBuffers();

        glfw.pollEvents();

        gl.clearColor(1, 0, 0, 1);
        gl.clear(gl.COLOR_BUFFER_BIT);

        return !self.window.?.shouldClose();
    }
};

pub const Mesh = struct {
    vertices: std.ArrayList(f32),
    indices: std.ArrayList(u32),

    vao: u32 = undefined,
    vbo: u32 = undefined,
    ebo: u32 = undefined,

    const Self = @This();

    pub fn init(allocator: Allocator) Mesh {
        return .{
            .vertices = std.ArrayList(f32).init(allocator),
            .indices = std.ArrayList(u32).init(allocator),
        };
    }

    pub fn create(self: *Self) void {
        gl.genVertexArrays(1, &self.vao);
        gl.genBuffers(1, &self.vbo);
        gl.genBuffers(1, &self.ebo);

        gl.bindVertexArray(self.vao);

        gl.bindBuffer(gl.ARRAY_BUFFER, self.vbo);
        gl.bufferData(
            gl.ARRAY_BUFFER,
            @intCast(self.vertices.items.len * @sizeOf(f32)),
            self.vertices.items[0..].ptr,
            gl.STATIC_DRAW,
        );

        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.ebo);
        gl.bufferData(
            gl.ELEMENT_ARRAY_BUFFER,
            @intCast(self.indices.items.len * @sizeOf(u32)),
            self.indices.items[0..].ptr,
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

        gl.bindBuffer(gl.ARRAY_BUFFER, 0);
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);
        gl.bindVertexArray(0);
    }

    pub fn bind(self: Self) void {
        gl.bindVertexArray(self.vao);
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.ebo);
        gl.drawElements(gl.TRIANGLES, @intCast(self.indices.items.len), gl.UNSIGNED_INT, null);

        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);
        gl.bindVertexArray(0);
    }

    pub fn deinit(self: Self) void {
        gl.deleteVertexArrays(1, &self.vao);
        gl.deleteBuffers(1, &self.vbo);
        gl.deleteBuffers(1, &self.ebo);

        self.vertices.deinit();
        self.indices.deinit();
    }
};

pub const Shader = struct {
    program: u32 = 0,

    vertSource: []const u8,
    fragSource: []const u8,

    const Self = @This();

    pub fn compile(self: *Self) void {
        const vertShader = gl.createShader(gl.VERTEX_SHADER);
        defer gl.deleteShader(vertShader);

        gl.shaderSource(vertShader, 1, &self.vertSource.ptr, null);
        gl.compileShader(vertShader);

        verifyShaderCompilation(vertShader, "vertex");

        const fragShader = gl.createShader(gl.FRAGMENT_SHADER);
        defer gl.deleteShader(fragShader);

        gl.shaderSource(fragShader, 1, &self.fragSource.ptr, null);
        gl.compileShader(fragShader);

        verifyShaderCompilation(fragShader, "fragment");

        self.program = gl.createProgram();
        gl.attachShader(self.program, vertShader);
        gl.attachShader(self.program, fragShader);
        gl.linkProgram(self.program);

        verifyProgramCompilation(self.program);
    }

    pub fn bind(self: Self) void {
        gl.useProgram(self.program);
    }

    pub fn deinit(self: Self) void {
        gl.deleteProgram(self.program);
    }

    fn verifyShaderCompilation(shader: gl.GLuint, name: []const u8) void {
        var success: gl.GLint = undefined;
        gl.getShaderiv(shader, gl.COMPILE_STATUS, &success);

        if (success == @intFromBool(false)) {
            var infoLog: [512]u8 = undefined;

            gl.getShaderInfoLog(shader, infoLog.len, null, &infoLog);

            std.debug.panic("Error: {s} shader compilation failed\n{s}", .{ name, infoLog });
        }
    }

    fn verifyProgramCompilation(program: u32) void {
        var success: gl.GLint = undefined;

        gl.getProgramiv(program, gl.LINK_STATUS, &success);
        if (success == @intFromBool(false)) {
            var infoLog: [512]u8 = undefined;

            gl.getProgramInfoLog(program, infoLog.len, null, &infoLog);

            std.debug.panic("Error: Shader linking failed\n{s}", .{infoLog});
        }
    }
};
