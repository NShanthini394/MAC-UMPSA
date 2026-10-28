extends Node2D
## Dense local mist leaves villagers a small moving pocket of nearby visibility.
## Nenek keeps a clear view; world effects stay below the HUD.

const MapGeometry = preload("res://scripts/map_geometry.gd")
const FOG_SHADER := """
shader_type canvas_item;
render_mode unshaded;
uniform sampler2D scene_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float fog_opacity = 0.99;
uniform float blur_strength = 4.0;
uniform float mist_density = 0.94;
uniform bool nearby_view = false;
uniform vec2 observer_position = vec2(0.0);
uniform vec2 fog_origin = vec2(0.0);
uniform float fog_radius = 180.0;
varying vec2 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy; }
float random_value(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float cloud(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(random_value(i), random_value(i + vec2(1.0, 0.0)), f.x),
               mix(random_value(i + vec2(0.0, 1.0)), random_value(i + vec2(1.0, 1.0)), f.x), f.y);
}
void fragment() {
    float smoke = cloud(UV * vec2(6.0, 5.0) + vec2(TIME * 0.07, TIME * 0.025));
    smoke = smoke * 0.65 + cloud(UV * 13.0 - TIME * 0.045) * 0.35;
    vec2 edge = smoothstep(vec2(0.0), vec2(0.045), UV) * smoothstep(vec2(0.0), vec2(0.045), vec2(1.0) - UV);
    vec3 blurred = textureLod(scene_texture, SCREEN_UV, blur_strength).rgb;
    vec3 mist = mix(blurred, vec3(0.69, 0.76, 0.78), mist_density + smoke * (1.0 - mist_density));
    float radial_edge = 1.0 - smoothstep(0.70, 1.0, distance(world_position, fog_origin) / fog_radius);
    // An upright pocket preserves the local character and the ground at their feet.
    float nearby_distance = length((world_position - observer_position + vec2(0.0, 26.0)) / vec2(42.0, 66.0));
    float pocket = nearby_view ? mix(0.10, 1.0, smoothstep(0.55, 1.0, nearby_distance)) : 1.0;
    COLOR = vec4(mist, edge.x * edge.y * radial_edge * fog_opacity * (0.96 + smoke * 0.04) * pocket);
}
"""

var _doors: Array = []
var _observer: Node2D
var _fog_materials: Array[ShaderMaterial] = []


func configure(map_index: int, kind: String, area_index: int, nenek_view: bool, origin: Vector2 = Vector2.ZERO, radius: float = 180.0, observer: Node2D = null) -> void:
	z_index = 80
	_observer = observer
	if kind == "fog":
		var shader := Shader.new()
		shader.code = FOG_SHADER
		for zone in MapGeometry.fog_regions(map_index, area_index, origin, radius):
			var fog := ColorRect.new()
			fog.position = zone.position
			fog.size = zone.size
			fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var fog_material := ShaderMaterial.new()
			fog_material.shader = shader
			fog_material.set_shader_parameter("fog_opacity", 0.10 if nenek_view else 0.99)
			fog_material.set_shader_parameter("blur_strength", 0.0 if nenek_view else 4.0)
			fog_material.set_shader_parameter("mist_density", 0.60 if nenek_view else 0.94)
			fog_material.set_shader_parameter("nearby_view", not nenek_view and is_instance_valid(_observer))
			fog_material.set_shader_parameter("fog_origin", origin)
			fog_material.set_shader_parameter("fog_radius", radius)
			fog.material = fog_material
			add_child(fog)
			_fog_materials.append(fog_material)
		_process(0.0)
	elif kind == "lock":
		_doors = MapGeometry.area_doors(map_index, area_index)
		queue_redraw()
	set_process(kind == "fog" and not nenek_view and is_instance_valid(_observer))


func _process(_delta: float) -> void:
	if not is_instance_valid(_observer): return
	for fog_material in _fog_materials:
		fog_material.set_shader_parameter("observer_position", _observer.global_position)


func _draw() -> void:
	for door in _doors:
		draw_rect(door, Color(0.35, 0.08, 0.40, 0.86))
		draw_rect(door, Color("ffd17c"), false, 2.0)
		draw_line(door.position, door.end, Color("ffd17c"), 3.0)
		draw_line(door.position + Vector2(door.size.x, 0), door.position + Vector2(0, door.size.y), Color("ffd17c"), 3.0)
