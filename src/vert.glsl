#version 330 core
layout (location = 0) in vec3 pos;

// uniform mat4 _P;
uniform vec3 _Offset;

// vec4 local2clip(vec4 localPos)
// {
//     return _P * localPos; // _v * _M *
// }

void main()
{
    // gl_Position = local2clip(vec4(pos, 1.0));
    // pos = pos + _Offset;
    vec3 p = pos + _Offset;
    gl_Position = vec4(p.x, p.y, p.z, 1.0);
}
