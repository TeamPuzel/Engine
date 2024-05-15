#version 330 core

layout(location = 0) in vec3 position;
layout(location = 1) in vec2 uv;
layout(location = 2) in vec4 color;

out vec2 vertex_uv;
out vec4 vertex_color;

uniform mat4x4 transform;

void main() {
    gl_Position = vec4(position, 1.0) * transform;
    
    vertex_uv = uv;
    vertex_color = color;
}
