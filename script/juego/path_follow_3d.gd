extends PathFollow3D

# Velocidad de movimiento
@export var speed: float = 2.0

func _process(delta: float) -> void:
	# Aumentamos el progreso a lo largo del camino según la velocidad
	progress += speed * delta
