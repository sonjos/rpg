# res://autoload/PlayerStats.gd
extends Node

#--------SIGNALS---------
signal level_up(new_level)
signal stats_changed()
signal revive_player(nueva_posicion)
signal enemy_health_changed(current, max_val)
signal enemy_died()

#----------const---------
const MAX_LEVEL : int = 30

#---------VAR (Variables Globales)
var ultimo_punto_control: Vector3 = Vector3.ZERO
var level : int = 1
var experiencia: int = 0
var experiencia_requerida: int = 100
var monedas: int = 0

var max_health : float = 100.0
var current_health : float = 100.0
var attack_power : float = 10.0
var defense : float = 0.0
var max_stamina : float = 100.0
var current_stamina : float = 100.0
var saqueo : float = 0.0
var agilidad : float = 1.0 # Multiplicador de velocidad base (1.0 = 100%)

var is_Bloqueo : bool = false
var player_state_machine : Node = null
var is_dead : bool = false
var menu_inventario_instancia: Control = null

var equipo : Dictionary = {
	"casco": null,
	"pechera": null,
	"arma": null,
	"anillo": null,
	"clave": null
}

#-------Misiones-------
var mision_activa_nombre: String = ""
var mision_activa_descripcion: String = ""
var mision_cantidad_requerida: int = 0
var mision_cantidad_actual: int = 0
var mision_item_nombre: String = ""
var mision_activa_completada: bool = false


func _ready() -> void:
	pass
	#reset_stats()

func reset_stats() -> void:
	level = 1
	experiencia = 0
	experiencia_requerida = 100
	monedas = 0
	max_health = 100.0
	current_health = max_health
	attack_power = 10.0
	defense = 0.0
	max_stamina = 100.0
	current_stamina = max_stamina
	saqueo = 0.0
	agilidad = 1.0
	is_Bloqueo = false

func ganar_experiencia(cantidad: int) -> void:
	experiencia += cantidad
	while experiencia >= experiencia_requerida and level < MAX_LEVEL:
		experiencia -= experiencia_requerida
		experiencia_requerida = int(experiencia_requerida * 1.5)
		add_level()
	emit_signal("stats_changed")

func ganar_monedas(cantidad: int) -> void:
	monedas += cantidad
	emit_signal("stats_changed")

func add_level() -> void:
	if level >= MAX_LEVEL:
		return
	level += 1
	max_health += 10.0
	attack_power += 1.5
	defense += 1.0
	max_stamina += 5.0
	current_stamina = max_stamina
	current_health = max_health
	emit_signal("level_up", level)
	emit_signal("stats_changed")

func consumir_stamina(cantidad: float) -> bool:
	if current_stamina >= cantidad:
		current_stamina -= cantidad
		current_stamina = max(0.0, current_stamina)
		emit_signal("stats_changed")
		return true
	return false

@export var tasa_recuperacion_stamina: float = 10.0
var esta_corriendo: bool = false

func _process(delta: float) -> void:
	if current_health > 0 and current_stamina < max_stamina:
		if not esta_corriendo and not is_Bloqueo:
			current_stamina += tasa_recuperacion_stamina * delta
			current_stamina = min(current_stamina, max_stamina)
			emit_signal("stats_changed")
			
func take_damage(raw_amount: float) -> void:
	if is_dead or is_Bloqueo:
		return
	var def_total = obtener_defensa_total()
	var final_damage = max(1.0, raw_amount - def_total)
	current_health = max(0.0, current_health - final_damage)
	
	emit_signal("stats_changed")
	if current_health <= 0:
		is_dead = true
		if player_state_machine:
			player_state_machine.transition_to("Muerte")

func revivir() -> void:
	is_dead = false
	current_health = max_health
	current_stamina = max_stamina
	emit_signal("stats_changed")
	emit_signal("revive_player", ultimo_punto_control)

func actualizar_vida_enemigo(current: float, max_val: float) -> void:
	emit_signal("enemy_health_changed", current, max_val)
	
func reportar_enemigo_muerto() -> void:
	emit_signal("enemy_died")



# --- CÁLCULO DE STATS TOTALES (BASE + EQUIPO) ---
func obtener_fuerza_total() -> float:
	var total = attack_power
	for slot in equipo:
		if equipo[slot] and "bonus_fuerza_poder" in equipo[slot]:
			total += equipo[slot].bonus_fuerza_poder
	return total

func obtener_defensa_total() -> float:
	var total = defense
	for slot in equipo:
		if equipo[slot] and "bonus_defensa" in equipo[slot]:
			total += equipo[slot].bonus_defensa
	return total

func obtener_saqueo_total() -> float:
	var total = saqueo
	for slot in equipo:
		if equipo[slot] and "bonus_saqueo" in equipo[slot]:
			total += equipo[slot].bonus_saqueo
	return total

func obtener_agilidad_total() -> float:
	var total = agilidad
	for slot in equipo:
		if equipo[slot] and "bonus_agilidad_velocidad" in equipo[slot]:
			total += equipo[slot].bonus_agilidad_velocidad
	return total

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Inventario"):
		if menu_inventario_instancia and is_instance_valid(menu_inventario_instancia):
			menu_inventario_instancia.queue_free()
		else:
			var escena = load("res://Escenas/Inventario/inventario_ui.tscn")
			if escena:
				menu_inventario_instancia = escena.instantiate()
				get_tree().root.add_child(menu_inventario_instancia)

func aceptar_mision(nombre: String, descripcion: String, cantidad: int, item_nombre: String) -> void:
	mision_activa_nombre = nombre
	mision_activa_descripcion = descripcion
	mision_cantidad_requerida = cantidad
	mision_item_nombre = item_nombre
	mision_cantidad_actual = 0
	mision_activa_completada = false
	if has_signal("stats_changed"):
		stats_changed.emit()

func completar_mision() -> void:
	mision_activa_completada = true
	if has_signal("stats_changed"):
		stats_changed.emit()
