extends GridContainer

# Definimos el tamaño de nuestro inventario: 3 de ancho x 6 de largo = 18 huecos totales
const COLUMNAS: int = 3
const FILAS: int = 6
const TOTAL_CASILLAS: int = COLUMNAS * FILAS

func _ready() -> void:
	columns = COLUMNAS
	PlayerStats.stats_changed.connect(actualizar_inventario)
	actualizar_inventario()

func actualizar_inventario() -> void:
	# 1. Limpiamos los elementos anteriores
	for hijo in get_children():
		hijo.queue_free()
		
	# 2. Creamos los huecos fijos (18 en total para nuestro 3x6)
	for i in range(TOTAL_CASILLAS):
		# Creamos un contenedor visual para cada casilla (slot)
		var slot = Panel.new()
		slot.custom_minimum_size = Vector2(50, 50) # Ajusta este tamaño según lo grande que sea tu zona gris
		
		# Si en el inventario del jugador hay un objeto en esta posición, le ponemos su icono
		if i < PlayerStats.inventario.size():
			var item = PlayerStats.inventario[i]
			var icono_rect = TextureRect.new()
			icono_rect.texture = item.icono
			icono_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icono_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icono_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT) # Ocupa todo el slot
			slot.add_child(icono_rect)
			
		add_child(slot)
