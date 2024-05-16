#version 330 core

in vec2 vertex_uv;

uniform sampler2D texture_id;

out vec4 out_color;

void main() {
    out_color = texture(texture_id, vertex_uv);
}
