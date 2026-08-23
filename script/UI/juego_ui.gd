extends CanvasLayer

var timer_dialogo: SceneTreeTimer

# Referencias directas a los elementos visuales
@onready var barra_vida: TextureProgressBar = $BarraVida
@onready var stamina_bar: TextureProgressBar = $StaminaBar
@onready var barra_experiencia: TextureProgressBar = $BarraExperiencia
@onready var contador_monedas_label: Label = $ContadorMonedas/Label

@export var player: CharacterBody3D 

func _ready() -> void:
	# Conexiones con el Autoload PlayerStats
	if PlayerStats.has_signal("stats_changed"):
		PlayerStats.connect("stats_changed", _actualizar_interfaz)
		PlayerStats.connect("enemy_health_changed", _on_enemy_health_changed)
		PlayerStats.connect("enemy_died", _on_enemy_died)
		
		# Conectar el cambio de nivel si quieres algún efecto en UI
		if PlayerStats.has_signal("level_up"):
			PlayerStats.connect("level_up", _on_level_up)
			
		$VidaEnemigo.visible = false
		print("UI conectada a PlayerStats correctamente.")
	
	_actualizar_interfaz()

func _actualizar_interfaz() -> void:
	# 1. Vida
	barra_vida.max_value = PlayerStats.max_health
	barra_vida.value = PlayerStats.current_health
	
	# 2. Estamina
	stamina_bar.max_value = PlayerStats.max_stamina
	stamina_bar.value = PlayerStats.current_stamina
	
	# 3. Experiencia (Vinculada directamente a PlayerStats)
	if barra_experiencia:
		barra_experiencia.max_value = PlayerStats.experiencia_requerida
		barra_experiencia.value = PlayerStats.experiencia
	
	# 4. Monedas
	if contador_monedas_label:
		contador_monedas_label.text = str(PlayerStats.monedas)

func _on_level_up(nuevo_nivel: int) -> void:
	# Puedes mostrar un mensaje breve o efecto visual cuando sube de nivel
	mostrar_dialogo("¡NIVEL AUMENTADO!", "Has alcanzado el nivel " + str(nuevo_nivel))

func _on_vida_cambiada(nueva_vida: float) -> void:
	barra_vida.value = nueva_vida
	
func mostrar_pantalla_muerte() -> void:
	if has_node("BtnRevivir"):
		$BtnRevivir.show()

func _on_btn_revivir_pressed() -> void:
	if has_node("BtnRevivir"):
		$BtnRevivir.hide()
	PlayerStats.revivir()
	
func _on_enemy_health_changed(current: float, max_val: float) -> void:
	$VidaEnemigo.visible = true
	$VidaEnemigo.max_value = max_val
	$VidaEnemigo.value = current
	
func _on_enemy_died() -> void:
	$VidaEnemigo.visible = false
	
func mostrar_dialogo(titulo: String, mensaje: String) -> void:
	$PanelDialogo.show()
	$PanelDialogo/TituloDialogo.text = titulo
	$PanelDialogo/TextoDialogo.text = mensaje
	
	get_tree().create_timer(3.0).timeout.connect(ocultar_dialogo)
		
func ocultar_dialogo() -> void:
	$PanelDialogo.hide()
