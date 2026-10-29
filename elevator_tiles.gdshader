shader_type spatial;

varying vec2 floor_position;

void vertex() {
 floor_position = VERTEX.xz;
}

void fragment() {
 vec2 grid = (floor_position + vec2(1.375, 1.325)) / 0.35;
 vec2 cell = fract(grid);
 float checker = mod(floor(grid.x) + floor(grid.y), 2.0);
 vec3 tile = mix(vec3(0.025), vec3(0.82, 0.80, 0.75), checker);
 float edge = min(min(cell.x, 1.0 - cell.x), min(cell.y, 1.0 - cell.y));
 float grout = 1.0 - smoothstep(0.008, 0.018, edge);
 ALBEDO = mix(tile, vec3(0.14, 0.13, 0.12), grout);
 ROUGHNESS = mix(0.38, 0.85, grout);
}
