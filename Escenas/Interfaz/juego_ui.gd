# res://Escenas/UI/juego_ui.gd
extends CanvasLayer

var _callback_opcion_actual: Callable = Callable()

@onready var barra_vida: TextureProgressBar = $BarraVida
@onready var stamina_bar: TextureProgressBar = $StaminaBar
@onready var barra_experiencia: TextureProgressBar = $BarraExperiencia
@onready var contador_monedas_label: Label = $ContadorMonedas/Label
@onready var texto_mision: RichTextLabel = $PanelMisiones/TextoMision
@onready var panel_misiones: Control = $PanelMisiones # Añadimos la referencia al panel
@export var player: CharacterBody3D 

func _ready() -> void:
	PlayerStats.stats_changed.connect(_actualizar_interfaz)
	PlayerStats.enemy_health_changed.connect(_on_enemy_health_changed)
	PlayerStats.enemy_died.connect(_on_enemy_died)
	PlayerStats.level_up.connect(_on_level_up)
		
	if has_node("VidaEnemigo"):
		$VidaEnemigo.visible = false
		
	# El panel de misiones empieza oculto por defecto al arrancar
	if panel_misiones:
		panel_misiones.visible = false
		
	# Conectamos con el nuevo QuestManager para actualizar la misión en tiempo real
	QuestManager.mision_actualizada.connect(_actualizar_interfaz_mision)
	
	_actualizar_interfaz()
	_actualizar_interfaz_mision()

# Detectar la tecla M para alternar la visibilidad del panel de misiones
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_M:
		if panel_misiones:
			panel_misiones.visible = not panel_misiones.visible

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

func _actualizar_interfaz_mision() -> void:
	if not texto_mision:
		return
		
	if QuestManager.mision_completada:
		texto_mision.text = "¡Misión Completada!"
	elif QuestManager.mision_aceptada:
		texto_mision.text = "Misión: %s\n- %s: %d / %d" % [
			QuestManager.mision_activa,
			QuestManager.item_objetivo_nombre,
			QuestManager.mision_cantidad_actual,
			QuestManager.cantidad_requerida
		]
	else:
		texto_mision.text = "Sin misiones activas."

func _on_level_up(nuevo_nivel: int) -> void:
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

func mostrar_dialogo_con_opciones(nombre: String, texto: String, texto_btn_1: String, callback_1: Callable, texto_btn_2: String = "", callback_2: Callable = Callable()) -> void:
	if has_node("CajaDialogoUI") and $CajaDialogoUI.has_method("mostrar_dialogo_con_opciones"):
		$CajaDialogoUI.mostrar_dialogo_con_opciones(nombre, texto, texto_btn_1, callback_1, texto_btn_2, callback_2)
