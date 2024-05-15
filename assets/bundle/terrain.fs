#version 330 core

in vec2 vertex_uv;
in vec4 vertex_color;

uniform sampler2D texture_id;

out vec4 out_color;

void main() {
    out_color = texture(texture_id, vertex_uv) * vertex_color;
}
