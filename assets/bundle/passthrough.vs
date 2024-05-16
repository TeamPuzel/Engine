#version 330 core

layout(location = 0) in vec3 position;
layout(location = 1) in vec2 uv;

out vec2 vertex_uv;

uniform mat4x4 transform;

void main() {
    gl_Position = transform * vec4(position, 1.0);
    vertex_uv = uv;
}
