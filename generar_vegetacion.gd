extends MultiMeshInstance3D

@export var limite_min := Vector2(-100.0, -100.0)
@export var limite_max := Vector2(100.0, 100.0)
@export var altura_raycast := 100.0

@export_group("Zona de la Aldea")
## Radio de protección para la aldea (en metros desde el centro 0,0)
@export var radio_aldea_limpio: float = 25.0

@export_group("Escala de Vegetación")
@export var escala_minima: float = 5.0
@export var escala_maxima: float = 10.0

@export_group("Material")
@export var textura_hierba: Texture2D
@export var usar_transparencia: bool = false
@export var color_base: Color = Color(0.2, 0.6, 0.15)

func _ready() -> void:
	if not multimesh:
		return
		
	_aplicar_material()
	await get_tree().physics_frame
	
	var space_state := get_world_3d().direct_space_state
	var total_instancias := multimesh.instance_count
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	
	for i in range(total_instancias):
		var pos_x := rng.randf_range(limite_min.x, limite_max.x)
		var pos_z := rng.randf_range(limite_min.y, limite_max.y)
		
		# FILTRO ALDEA: Calcular distancia al centro (0,0)
		var distancia_al_centro := Vector2(pos_x, pos_z).length()
		if distancia_al_centro < radio_aldea_limpio:
			# Ocultar la hierba dentro de la aldea
			multimesh.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ZERO), Vector3(0, -500, 0)))
			continue
		
		var origen := Vector3(pos_x, altura_raycast, pos_z)
		var destino := Vector3(pos_x, -altura_raycast, pos_z)
		
		var query := PhysicsRayQueryParameters3D.create(origen, destino)
		var impacto := space_state.intersect_ray(query)
		
		var pos_final := Vector3(pos_x, 0.0, pos_z)
		var normal := Vector3.UP
		
		if impacto:
			pos_final = impacto.position
			normal = impacto.normal
			
		var up := normal
		var forward := Vector3.FORWARD
		if abs(up.dot(forward)) > 0.99:
			forward = Vector3.RIGHT
		var right := up.cross(forward).normalized()
		forward = right.cross(up).normalized()
		
		var basis_rotada := Basis(right, up, forward)
		basis_rotada = basis_rotada.rotated(up, rng.randf_range(0.0, TAU))
		
		var escala_random := rng.randf_range(escala_minima, escala_maxima)
		var basis_escalada := basis_rotada.scaled(Vector3(escala_random, escala_random, escala_random))
		
		var transform := Transform3D(basis_escalada, pos_final)
		multimesh.set_instance_transform(i, transform)
	
	custom_aabb = AABB(Vector3(-200.0, -50.0, -200.0), Vector3(400.0, 150.0, 400.0))

func _aplicar_material() -> void:
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.9
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	if textura_hierba:
		mat.albedo_texture = textura_hierba
		if usar_transparencia:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			mat.alpha_scissor_threshold = 0.5
	else:
		mat.albedo_color = color_base
		
	material_override = mat
