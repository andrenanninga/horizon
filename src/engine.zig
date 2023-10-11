const std = @import("std");
const gl = @import("gl");

const Allocator = std.mem.Allocator;

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

        Shader.verifyShaderCompilation(vertShader, "vertex");

        const fragShader = gl.createShader(gl.FRAGMENT_SHADER);
        defer gl.deleteShader(fragShader);

        gl.shaderSource(fragShader, 1, &self.fragSource.ptr, null);
        gl.compileShader(fragShader);

        Shader.verifyShaderCompilation(fragShader, "fragment");

        self.program = gl.createProgram();
        gl.attachShader(self.program, vertShader);
        gl.attachShader(self.program, fragShader);
        gl.linkProgram(self.program);

        Shader.verifyProgramCompilation(self.program);
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
