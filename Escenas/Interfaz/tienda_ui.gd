extends Control

signal tienda_cerrada

@export var items_en_venta: Array[ItemData] = []

@onready var contenedor_comprar: VBoxContainer = $PanelComprar/ScrollContainer/VboxComprar
@onready var contenedor_vender: VBoxContainer = $PanelVender/VBoxVender

# Referencias directas a los botones ubicados en PanelComprar
@onready var btn_armas: Button = $PanelComprar/Armas
@onready var btn_armaduras: Button = $PanelComprar/Armaduras
@onready var btn_consumibles: Button = $PanelComprar/Consumibles
@onready var btn_abalorios: Button = $PanelComprar/Ablorios
@onready var btn_mochilas: Button = $PanelComprar/Mochilas

# Categoría actual seleccionada ("armas", "armaduras", "consumibles", "abalorios", "mochilas")
var categoria_actual: String = "armas"

func _ready() -> void:
	hide()
	var btn_cerrar = find_child("BtnCerrar", true, false)
	if btn_cerrar:
		if not btn_cerrar.pressed.is_connected(cerrar_tienda):
			btn_cerrar.pressed.connect(cerrar_tienda)
			
	# Conectamos los botones de las secciones de la tienda
	if btn_armas: btn_armas.pressed.connect(func(): cambiar_categoria("armas"))
	if btn_armaduras: btn_armaduras.pressed.connect(func(): cambiar_categoria("armaduras"))
	if btn_consumibles: btn_consumibles.pressed.connect(func(): cambiar_categoria("consumibles"))
	if btn_abalorios: btn_abalorios.pressed.connect(func(): cambiar_categoria("abalorios"))
	if btn_mochilas: btn_mochilas.pressed.connect(func(): cambiar_categoria("mochilas"))

func abrir_tienda() -> void:
	show()
	actualizar_tienda()

func cerrar_tienda() -> void:
	hide()
	tienda_cerrada.emit()

func cambiar_categoria(nueva_categoria: String) -> void:
	categoria_actual = nueva_categoria
	actualizar_lista_comprar()

func actualizar_tienda() -> void:
	actualizar_lista_comprar()
	actualizar_lista_vender()

func actualizar_lista_comprar() -> void:
	if not contenedor_comprar:
		return
		
	for hijo in contenedor_comprar.get_children():
		hijo.queue_free()

	# Añadimos separación vertical para que no se vean como un "pegote"
	contenedor_comprar.add_theme_constant_override("separation", 6)

	for item in items_en_venta:
		if not item:
			continue
			
		var es_de_esta_categoria = false
		match categoria_actual:
			"armas":
				if item.tipo == 0: es_de_esta_categoria = true
			"armaduras":
				if item.tipo == 1: es_de_esta_categoria = true
			"consumibles":
				if item.tipo == 2: es_de_esta_categoria = true
			"abalorios":
				if item.tipo == 5: es_de_esta_categoria = true
			"mochilas":
				if item.tipo == 4: es_de_esta_categoria = true
				
		if not es_de_esta_categoria:
			continue
			
		var panel_slot = PanelContainer.new()
		panel_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Fondo más definido y elegante para cada objeto
		var style_slot = StyleBoxFlat.new()
		style_slot.bg_color = Color("#121826F0")
		style_slot.border_color = Color("#4a3123")
		style_slot.set_border_width_all(1)
		style_slot.set_corner_radius_all(6)
		panel_slot.add_theme_stylebox_override("panel", style_slot)

		var h_box = HBoxContainer.new()
		h_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h_box.add_theme_constant_override("separation", 10)
		h_box.add_theme_constant_override("margin_left", 10)
		h_box.add_theme_constant_override("margin_right", 10)
		h_box.add_theme_constant_override("margin_top", 8)
		h_box.add_theme_constant_override("margin_bottom", 8)

		if item.icono:
			var texture_rect = TextureRect.new()
			texture_rect.texture = item.icono
			texture_rect.custom_minimum_size = Vector2(32, 32)
			texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			h_box.add_child(texture_rect)

		var lbl = Label.new()
		lbl.text = "%s - %d🪙" % [item.nombre, item.precio_compra]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.clip_text = true
		
		lbl.add_theme_color_override("font_color", Color("#f3e5ab"))
		lbl.add_theme_color_override("font_shadow_color", Color("#000000"))
		lbl.add_theme_constant_override("shadow_offset_x", 1)
		lbl.add_theme_constant_override("shadow_offset_y", 1)
		h_box.add_child(lbl)

		var btn = Button.new()
		btn.text = "Comprar"
		btn.size_flags_horizontal = Control.SIZE_SHRINK_END
		btn.pressed.connect(func(): _comprar_item(item))
		h_box.add_child(btn)

		panel_slot.add_child(h_box)
		contenedor_comprar.add_child(panel_slot)

func actualizar_lista_vender() -> void:
	if not contenedor_vender:
		return
		
	for hijo in contenedor_vender.get_children():
		hijo.queue_free()

	for slot in InventarioManager.inventario:
		if not slot or not slot.has("item") or not slot["item"]:
			continue
			
		var item: ItemData = slot["item"]
		var cantidad: int = slot["cantidad"]
			
		var panel_slot = PanelContainer.new()
		panel_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var style_slot = StyleBoxFlat.new()
		style_slot.bg_color = Color("#1a2035EE")
		style_slot.border_color = Color("#3d251e")
		style_slot.set_border_width_all(1)
		style_slot.set_corner_radius_all(4)
		panel_slot.add_theme_stylebox_override("panel", style_slot)

		var h_box = HBoxContainer.new()
		h_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h_box.add_theme_constant_override("separation", 10)
		h_box.add_theme_constant_override("margin_left", 8)
		h_box.add_theme_constant_override("margin_right", 8)
		h_box.add_theme_constant_override("margin_top", 6)
		h_box.add_theme_constant_override("margin_bottom", 6)

		if item.icono:
			var texture_rect = TextureRect.new()
			texture_rect.texture = item.icono
			texture_rect.custom_minimum_size = Vector2(28, 28)
			texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			h_box.add_child(texture_rect)

		var precio_vender = int(item.precio_compra / 2)

		var lbl = Label.new()
		lbl.text = "%s (x%d) - %d🪙" % [item.nombre, cantidad, precio_vender]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		lbl.add_theme_color_override("font_color", Color("#e6c280"))
		lbl.add_theme_color_override("font_shadow_color", Color("#000000"))
		lbl.add_theme_constant_override("shadow_offset_x", 1)
		lbl.add_theme_constant_override("shadow_offset_y", 1)
		h_box.add_child(lbl)

		var btn = Button.new()
		btn.text = "Vender"
		btn.pressed.connect(func(): _vender_item(item, precio_vender))
		h_box.add_child(btn)

		panel_slot.add_child(h_box)
		contenedor_vender.add_child(panel_slot)

func _comprar_item(item: ItemData) -> void:
	var precio = item.precio_compra
	if "monedas" in PlayerStats and PlayerStats.monedas >= precio:
		PlayerStats.ganar_monedas(-precio)
		InventarioManager.recoger_item(item)
		actualizar_tienda()
	else:
		print("Te faltan monedas")

func _vender_item(item: ItemData, precio_vender: int) -> void:
	if InventarioManager.remover_items_por_nombre(item.nombre, 1):
		PlayerStats.ganar_monedas(precio_vender)
		actualizar_tienda()
	else:
		print("No se pudo vender el objeto")
