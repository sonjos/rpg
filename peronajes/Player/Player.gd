# res://Scripts/Player.gd
extends CharacterBody3D

signal experiencia_cambiada(nueva_exp: int)
@export var mouse_sensitivity : float = 0.003
@onready var animation_player : AnimationPlayer = find_child("AnimationPlayer", true, false)
@onready var state_machine = $State_Machine
@onready var raycast: RayCast3D = $SpringArm3D/Camera3D/DetectorInteraccion3D
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
	# Si está congelado en un diálogo, ignoramos los movimientos de cámara e interacciones
	if esta_congelado:
		return
	
	# Rotación horizontal con el ratón
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		# Opcional: Rotación vertical de la cámara (SpringArm)[cite: 7]
		var spring_arm = $SpringArm3D
		if spring_arm:
			spring_arm.rotate_x(-event.relative.y * mouse_sensitivity)
			# Limitamos la rotación para que no dé la vuelta completa[cite: 7]
			spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-60), deg_to_rad(60))
	
	if event.is_action_pressed("Pause"):
		if pause_menu:
			if pause_menu.visible:
				pause_menu.cerrar_pausa()
			else:
				pause_menu.abrir_pausa()
				
	# Interacción mediante RayCast[cite: 7]
	if event.is_action_pressed("Interactuar"):
		if raycast and raycast.is_colliding():
			var colisionador = raycast.get_collider()
		
			# Sube por la jerarquía (Hijo -> Padre -> Raíz) hasta encontrar el script[cite: 7]
			var objetivo = colisionador
			while objetivo != null:
				if objetivo.has_method("interactuar"):
					objetivo.interactuar()
					break
				objetivo = objetivo.get_parent()

func _input(event: InputEvent) -> void:
	# Si presionas ESC, liberas el ratón (útil para salir del juego o entrar a menús)[cite: 7]
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
# Función que llamará el enemigo cuando te golpee[cite: 7]
func recibir_dano_jugador(cantidad: float) -> void:
	# 1. Aplicamos el dano a través del Autoload global PlayerStats[cite: 7]
	if PlayerStats:
		PlayerStats.take_damage(cantidad)
		print("¡Jugador herido! dano recibido: ", cantidad)
	
	# 2. Buscamos la máquina de estados de salud y activamos su reacción de golpe[cite: 7]
	var health_state_machine = get_node_or_null("HealthStateController") 
	if health_state_machine and health_state_machine.has_method("take_damage_and_react"):
		health_state_machine.take_damage_and_react(cantidad)
		
func ganar_experiencia(cantidad: int) -> void:
	experiencia_actual += cantidad
	print("Experiencia total: ", experiencia_actual)
	emit_signal("experiencia_cambiada", experiencia_actual) # Avisamos a quien esté escuchando[cite: 7]
