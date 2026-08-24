@tool
extends Area3D

# Exportamos el recurso
@export var item_a_recolectar: ItemData:
	set(value):
		item_a_recolectar = value
		_actualizar_icono()

# Cambiamos esto: Usamos @onready para asegurar que el nodo existe, 
# pero le añadimos una comprobación extra para el @tool
@onready var sprite_3d: Sprite3D = $Sprite3D

func _ready() -> void:
	# Al iniciar la escena, siempre actualizamos
	_actualizar_icono()
	
	if not Engine.is_editor_hint():
		if not body_entered.is_connected(_on_body_entered):
			body_entered.connect(_on_body_entered)

func _actualizar_icono() -> void:
	# Buscamos el nodo de forma segura
	var sprite = get_node_or_null("Sprite3D")
	if not sprite:
		return
	
	# AQUÍ ESTÁ EL TRUCO: 
	# Si hemos asignado un recurso, usamos su icono.
	# Si no, ponemos uno por defecto para que se vea algo en el editor.
	if item_a_recolectar and item_a_recolectar.get("icono"):
		sprite.texture = item_a_recolectar.icono
	else:
		# Ponemos una textura vacía o un icono de "Error/Default" 
		# para que no nos dé error si no hay nada asignado.
		sprite.texture = null

func _on_body_entered(body: Node3D) -> void:
	if not Engine.is_editor_hint():
		print("¡ALGO HA ENTRADO EN EL ÁREA!: ", body.name)
		
		if body.is_in_group("Player") or body.name == "Player":
			if item_a_recolectar:
				InventarioManager.recoger_item(item_a_recolectar)
				print("¡Objeto recogido con éxito!")
				queue_free()
