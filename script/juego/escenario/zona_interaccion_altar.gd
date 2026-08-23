
extends Area3D

@export var aviso_label: Label
@export var panel_dialogo: Control 
@export var texto_dialogo: RichTextLabel 
@export var caliz_mesh: MeshInstance3D # <--- Apuntando directamente al cáliz

var escala_original: Vector3 = Vector3.ONE
var jugador_en_zona: bool = false
var interactuado: bool = false
var tween_brillo: Tween

func _ready() -> void:
	if aviso_label:
		aviso_label.visible = false
	if panel_dialogo:
		panel_dialogo.visible = false
	if caliz_mesh:
		escala_original = caliz_mesh.scale

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("jugador"):
		jugador_en_zona = true
		if aviso_label and not interactuado:
			aviso_label.text = "Las runas del cáliz parpadean tenuemente... [Presiona F]"
			aviso_label.visible = true
			
		# Animación de parpadeo místico en el cáliz
		iniciar_parpadeo_caliz()

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("jugador"):
		jugador_en_zona = false
		if aviso_label:
			aviso_label.visible = false
		if panel_dialogo:
			panel_dialogo.visible = false
			interactuado = false 
			
		# Apagamos el brillo del cáliz al alejarnos
		detener_parpadeo_caliz()

func iniciar_parpadeo_caliz() -> void:
	if not caliz_mesh: return
	
	if tween_brillo and tween_brillo.is_valid():
		tween_brillo.kill()
		
	# Hacemos que el cáliz respire (suba y baje de tamaño suavemente)
	tween_brillo = create_tween().set_loops()
	tween_brillo.tween_property(caliz_mesh, "scale", escala_original * 1.15, 1.0)
	tween_brillo.tween_property(caliz_mesh, "scale", escala_original, 1.0)
	
func detener_parpadeo_caliz() -> void:
	if tween_brillo and tween_brillo.is_valid():
		tween_brillo.kill()
	
	if caliz_mesh:
		caliz_mesh.scale = escala_original

func _input(event: InputEvent) -> void:
	if jugador_en_zona and not interactuado:
		if event.is_action_pressed("interactuar") or (event is InputEventKey and event.pressed and event.keycode == KEY_F):
			mostrar_historia()

func mostrar_historia() -> void:
	interactuado = true
	if aviso_label:
		aviso_label.visible = false
	if panel_dialogo:
		panel_dialogo.visible = true
	if texto_dialogo:
		texto_dialogo.text = "[center][b]El Cáliz de Oakhaven[/b]\n\nLas runas del cáliz parpadean tenuemente. Al acercarte, notas un calor extraño que desafía la piedra fría del santuario.[/center]"
		texto_dialogo.visible_characters = -1
