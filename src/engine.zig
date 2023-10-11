const gl = @import("gl");

pub const Mesh = struct {
    vertices: [32]f32 = [1]f32{32} ** 32,
    indices: [32]u32 = [1]u32{32} ** 32,

    vertexCount: i32 = 0,
    indexCount: i32 = 0,

    vao: u32 = undefined,
    vbo: u32 = undefined,
    ebo: u32 = undefined,

    const Self = @This();

    pub fn create(self: *Self) void {
        gl.genVertexArrays(1, &self.vao);
        gl.genBuffers(1, &self.vbo);
        gl.genBuffers(1, &self.ebo);

        gl.bindVertexArray(self.vao);

        gl.bindBuffer(gl.ARRAY_BUFFER, self.vbo);
        gl.bufferData(
            gl.ARRAY_BUFFER,
            self.vertexCount * @sizeOf(f32),
            self.vertices[0..].ptr,
            gl.STATIC_DRAW,
        );

        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.ebo);
        gl.bufferData(
            gl.ELEMENT_ARRAY_BUFFER,
            self.indexCount * @sizeOf(u32),
            self.indices[0..].ptr,
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
        gl.drawElements(gl.TRIANGLES, self.indexCount, gl.UNSIGNED_INT, null);

        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);
        gl.bindVertexArray(0);
    }

    pub fn deinit(self: Self) void {
        gl.deleteVertexArrays(1, &self.vao);
        gl.deleteBuffers(1, &self.vbo);
        gl.deleteBuffers(1, &self.ebo);
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

        self.verifyShaderCompilation(vertShader, "vertex");

        const fragShader = gl.createShader(gl.FRAGMENT_SHADER);
        defer gl.deleteShader(fragShader);

        gl.shaderSource(fragShader, 1, &self.fragSource.ptr, null);
        gl.compileShader(fragShader);

        self.verifyShaderCompilation(fragShader, "fragment");

        self.program = gl.createProgram();
        gl.attachShader(self.program, vertShader);
        gl.attachShader(self.program, fragShader);
        gl.linkProgram(self.program);

        self.verifyProgramCompilation(self.program);
    }

    pub fn bind(self: Self) void {
        gl.useProgram(self.program);
    }

    pub fn deinit(self: Self) void {
        gl.deleteProgram(self.program);
    }

    fn verifyShaderCompilation(self: *Self, shader: gl.GLuint, name: []const u8) void {
        _ = self;
        var success: gl.GLint = undefined;
        gl.getShaderiv(shader, gl.COMPILE_STATUS, &success);

        if (success == @intFromBool(false)) {
            var infoLog: [512]u8 = undefined;

            gl.getShaderInfoLog(shader, infoLog.len, null, &infoLog);

            std.debug.panic("Error: {s} shader compilation failed\n{s}", .{ name, infoLog });
        }
    }

    fn verifyProgramCompilation(self: *Self, program: u32) void {
        _ = self;
        var success: gl.GLint = undefined;

        gl.getProgramiv(program, gl.LINK_STATUS, &success);
        if (success == @intFromBool(false)) {
            var infoLog: [512]u8 = undefined;

            gl.getProgramInfoLog(program, infoLog.len, null, &infoLog);

            std.debug.panic("Error: Shader linking failed\n{s}", .{infoLog});
        }
    }
};
