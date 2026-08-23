extends CanvasLayer

# Referencias directas a los elementos visuales del jugador
@onready var barra_vida: TextureProgressBar = $BarraVida
@onready var stamina_bar: TextureProgressBar = $StaminaBar
@onready var barra_experiencia: TextureProgressBar = $BarraExperiencia
@onready var contador_monedas_label: Label = $ContadorMonedas/Label

@export var player: CharacterBody3D 

func _ready() -> void:
	# Conexión directa de señales de estadísticas
	PlayerStats.stats_changed.connect(_actualizar_interfaz)
	PlayerStats.enemy_health_changed.connect(_on_enemy_health_changed)
	PlayerStats.enemy_died.connect(_on_enemy_died)
	PlayerStats.level_up.connect(_on_level_up)
		
	if has_node("VidaEnemigo"):
		$VidaEnemigo.visible = false
	
	_actualizar_interfaz()

func _actualizar_interfaz() -> void:
	if barra_vida:
		barra_vida.max_value = PlayerStats.max_health
		barra_vida.value = PlayerStats.current_health
	if stamina_bar:
		stamina_bar.max_value = PlayerStats.max_stamina
		stamina_bar.value = PlayerStats.current_stamina
	if barra_experiencia:
		barra_experiencia.max_value = PlayerStats.experiencia_requerida
		barra_experiencia.value = PlayerStats.experiencia
	if contador_monedas_label:
		contador_monedas_label.text = str(PlayerStats.monedas)

func _on_level_up(nuevo_nivel: int) -> void:
	# Si quieres que al subir de nivel también llame a la caja de diálogo mediante el grupo HUD:
	var hud = get_tree().get_first_node_in_group("HUD")
	if hud and hud.has_method("mostrar_dialogo"):
		hud.mostrar_dialogo("¡NIVEL AUMENTADO!", "Has alcanzado el nivel " + str(nuevo_nivel))

func mostrar_pantalla_muerte() -> void:
	if has_node("BtnRevivir"):
		$BtnRevivir.show()

func _on_btn_revivir_pressed() -> void:
	if has_node("BtnRevivir"):
		$BtnRevivir.hide()
	PlayerStats.revivir()
	
func _on_enemy_health_changed(current: float, max_val: float) -> void:
	if has_node("VidaEnemigo"):
		$VidaEnemigo.visible = true
		$VidaEnemigo.max_value = max_val
		$VidaEnemigo.value = current
	
func _on_enemy_died() -> void:
	if has_node("VidaEnemigo"):
		$VidaEnemigo.visible = false

func mostrar_dialogo(nombre: String, texto: String) -> void:
	var caja = get_node_or_null("ContenedorDialogo")
	if not caja:
		caja = get_node_or_null("PanelDialogo")
	
	if not caja:
		push_error("No hay contenedor de diálogo en la UI.")
		return
		
	caja.show()
	
	# Forzar estilo dorado y fondo oscuro
	if caja is PanelContainer or caja.has_theme_stylebox_override("panel") or "Panel" in caja.name:
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color.html("#14141EE0")
		estilo.set_border_width_all(2)
		estilo.border_color = Color.html("#D9A736")
		estilo.set_corner_radius_all(12)
		caja.add_theme_stylebox_override("panel", estilo)

	var n_label = caja.get_node_or_null("MarginContainer/VBoxContainer/NombreLabel")
	if not n_label: n_label = caja.get_node_or_null("NombreLabel")
	
	var t_label = caja.get_node_or_null("MarginContainer/VBoxContainer/TextoLabel")
	if not t_label: t_label = caja.get_node_or_null("TextoLabel")

	if n_label:
		n_label.text = nombre
		n_label.add_theme_color_override("font_color", Color.html("#FFD700"))
		
	if t_label:
		t_label.text = texto
		if "default_color" in t_label:
			t_label.add_theme_color_override("default_color", Color.html("#F0F0F0"))
		elif "font_color" in t_label:
			t_label.add_theme_color_override("font_color", Color.html("#F0F0F0"))

func ocultar_dialogo() -> void:
	var caja = get_node_or_null("ContenedorDialogo")
	if not caja: caja = get_node_or_null("PanelDialogo")
	if caja:
		caja.hide()
