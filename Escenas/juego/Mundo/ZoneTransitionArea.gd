extends Area3D

@export var target_atmosphere: ZoneAtmosphere
@export var transition_duration: float = 2.0

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("Player"):
		return
		
	var main_env_node = get_node_or_null("/root/MainWorld/WorldEnvironment")
	if not main_env_node:
		main_env_node = get_node_or_null("/root/PruebasClima/WorldEnvironment")
	if not main_env_node:
		main_env_node = get_node_or_null("../WorldEnvironment")
		
	var main_sun_node = get_node_or_null("/root/MainWorld/DirectionalLight3D")
	if not main_sun_node:
		main_sun_node = get_node_or_null("/root/PruebasClima/DirectionalLight3D")
	if not main_sun_node:
		main_sun_node = get_node_or_null("../DirectionalLight3D")
	
	if not main_env_node is WorldEnvironment:
		print("Fallo: No se encontró un nodo WorldEnvironment válido.")
		return
		
	if not main_sun_node is DirectionalLight3D:
		print("Fallo: No se encontró un nodo DirectionalLight3D válido.")
		return
		
	if not target_atmosphere:
		print("Fallo: El Area3D no tiene asignado ningún recurso ZoneAtmosphere.")
		return
		
	print("¡Transición iniciada hacia la zona: ", target_atmosphere.zone_name, "!")
	
	var current_env = main_env_node.environment
	# Corrección para acceder al material del cielo en Godot 4
	var sky_material = current_env.sky.sky_material as ProceduralSkyMaterial if current_env and current_env.sky else null
	
	var tween = create_tween().set_parallel(true)
	
	# 1. Transición de la Luz Solar Única
	tween.tween_property(main_sun_node, "light_color", target_atmosphere.sun_color, transition_duration)
	tween.tween_property(main_sun_node, "light_energy", target_atmosphere.sun_energy, transition_duration)
	tween.tween_property(main_sun_node, "rotation_degrees", target_atmosphere.sun_rotation_degrees, transition_duration)
	
	# 2. Transición de Niebla y Ambiente
	tween.tween_property(current_env, "fog_density", target_atmosphere.fog_density, transition_duration)
	tween.tween_property(current_env, "fog_light_color", target_atmosphere.fog_light_color, transition_duration)
	tween.tween_property(current_env, "ambient_light_color", target_atmosphere.ambient_light_color, transition_duration)
	
	# 3. Transición de los Colores del Cielo
	if sky_material:
		tween.tween_property(sky_material, "sky_top_color", target_atmosphere.sky_top_color, transition_duration)
		tween.tween_property(sky_material, "sky_horizon_color", target_atmosphere.sky_horizon_color, transition_duration)
