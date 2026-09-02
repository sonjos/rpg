# res://Scripts/Player.gd
extends CharacterBody3D

func play_step_sound():
	$AudioStreamPlayer3D.play()

signal experiencia_cambiada(nueva_exp: int)
@export var mouse_sensitivity : float = 0.003
@onready var animation_player : AnimationPlayer = find_child("AnimationPlayer", true, false)
@onready var state_machine = $State_Machine
@onready var raycast: RayCast3D = $DetectorInteraccion3D
@onready var pause_menu: Control
# Variable para saber si el jugador está congelado (por ejemplo, en un diálogo)
var esta_congelado: bool = false

# Diccionario centralizado de animaciones para no tener que escribirlas a mano en los estados
var anims = {
	"idle": "Idle",
	"idle_weapon": "Idle_Weapon",
	"idle_attacking": "Idle_Attacking",
	"walk": "Walk",
	"run": "Run",
	"run_weapon": "Run_Weapon",
	"attack_1": "Sword_Attack",
	"attack_2": "Sword_Attack2",
	"block": "Punch",
	"jump": "Jump",        
	"roll": "Roll",
	"hit": "RecieveHit",
	"death": "Death",
	"pickup": "PickUp"
}
var experiencia_actual: int = 0

func _ready() -> void:
	if raycast:
		raycast.add_exception(self)
	PlayerStats.player_state_machine = state_machine
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if PlayerStats.ultimo_punto_control == Vector3.ZERO:
		PlayerStats.ultimo_punto_control = global_position
	if animation_player:
		# Configuramos los loops de forma segura si existen
		if animation_player.has_animation(anims["walk"]):
			animation_player.get_animation(anims["walk"]).loop_mode = Animation.LOOP_LINEAR
		if animation_player.has_animation(anims["run"]):
			animation_player.get_animation(anims["run"]).loop_mode = Animation.LOOP_LINEAR
		if animation_player.has_animation(anims["run_weapon"]):
			animation_player.get_animation(anims["run_weapon"]).loop_mode = Animation.LOOP_LINEAR

# Función que llama la caja de diálogo para congelar/descongelar al jugador
func set_congelado(estado: bool) -> void:
	esta_congelado = estado

# Función de ayuda para reproducir animaciones de forma limpia desde cualquier estado
func play_anim(anim_key: String, custom_blend: float = -1.0) -> void:
	if animation_player and anims.has(anim_key):
		var anim_name = anims[anim_key]
		if animation_player.has_animation(anim_name):
			if animation_player.current_animation != anim_name:
				animation_player.play(anim_name, custom_blend)
		else:
			print("Aviso: La animación '" + anim_name + "' no existe en el AnimationPlayer.")

func _unhandled_input(event: InputEvent) -> void:
	# Si el ratón está libre (jugador muerto o menú abierto) o el jugador está congelado, ignorar controles de cámara/interacción
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE or esta_congelado:
		return
	
	# Rotación horizontal con el ratón
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		var spring_arm = $SpringArm3D
		if spring_arm:
			spring_arm.rotate_x(-event.relative.y * mouse_sensitivity)
			spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-60), deg_to_rad(60))
	
	if event.is_action_pressed("Pause"):
		if pause_menu:
			if pause_menu.visible:
				pause_menu.cerrar_pausa()
			else:
				pause_menu.abrir_pausa()
				
	# Interacción mediante RayCast usando "Interactuar" con I mayúscula
	if event.is_action_pressed("Interactuar"):
		if raycast and raycast.is_colliding():
			var colisionador = raycast.get_collider()
		
			# Sube por la jerarquía hasta encontrar la raíz o nodo con script de interacción
			var objetivo = colisionador
			while objetivo != null:
				if objetivo.has_method("interactuar"):
					objetivo.interactuar(self) # Le enviamos la referencia del player a la puerta
					break
				elif objetivo.has_method("Interactuar"):
					objetivo.Interactuar()
					break
				objetivo = objetivo.get_parent()

func _input(event: InputEvent) -> void:
	# 1. Si el ratón ya está visible (por estar muerto o en menú), no procesamos entrada de ratón ni cámara
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		return

	# 2. Si presionas ESC (ui_cancel), liberas el ratón manualmente
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func recibir_dano_jugador(cantidad: float) -> void:
	# 1. Aplicamos el dano a través del Autoload global PlayerStats
	if PlayerStats:
		PlayerStats.take_damage(cantidad)
		print("¡Jugador herido! dano recibido: ", cantidad)
	
	# 2. Buscamos la máquina de estados de salud y activamos su reacción de golpe
	var health_state_machine = get_node_or_null("HealthStateController") 
	if health_state_machine and health_state_machine.has_method("take_damage_and_react"):
		health_state_machine.take_damage_and_react(cantidad)
		
func ganar_experiencia(cantidad: int) -> void:
	experiencia_actual += cantidad
	print("Experiencia total: ", experiencia_actual)
	emit_signal("experiencia_cambiada", experiencia_actual) # Avisamos a quien esté escuchando

# Función puente para que la puerta o cofres comprueben si tienes una llave válida
func obtener_llave_en_inventario(nivel_requerido: int) -> ItemData:
	# Recorremos la sección de objetos clave
	for slot in InventarioManager.objetos_clave:
		var item = slot["item"] as ItemData
		if item and item.tipo == 3: # Tipo Clave
			if "nivel_acceso" in item and item.nivel_acceso >= nivel_requerido:
				return item
				
	# Por compatibilidad, revisamos también la mochila general si hiciera falta
	for slot in InventarioManager.inventario:
		var item = slot["item"] as ItemData
		if item and item.tipo == 3:
			if "nivel_acceso" in item and item.nivel_acceso >= nivel_requerido:
				return item

	return null
