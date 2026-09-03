class_name ZoneAtmosphere
extends Resource

@export var zone_name: String
@export_range(0.0, 1.0) var fog_density: float = 0.0
@export var fog_light_color: Color = Color.WHITE
@export var ambient_light_color: Color = Color.WHITE
@export var sun_color: Color = Color.WHITE
@export var sun_energy: float = 1.0
@export var sun_rotation_degrees: Vector3 = Vector3(-45, 45, 0) # Inclinación del sol
@export var sky_top_color: Color = Color(0.3, 0.5, 0.8)
@export var sky_horizon_color: Color = Color(0.6, 0.7, 0.9)
