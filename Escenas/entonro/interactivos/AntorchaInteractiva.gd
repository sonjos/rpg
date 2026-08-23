extends StaticBody3D

@export var id_antorcha: int = 1
@export var gestor_puzle: Node3D

@onready var luz: OmniLight3D = $OmniLight3D

var encendida: bool = false
func _ready() -> void:
	apagar() # Garantiza que empiece apagada al iniciar la escena
func interactuar() -> void:
	if encendida:
		return
		
	encendida = true
	if luz:
		luz.visible = true
		
	if gestor_puzle and gestor_puzle.has_method("registrar_activacion"):
		gestor_puzle.registrar_activacion(id_antorcha)

func apagar() -> void:
	encendida = false
	if luz:
		luz.visible = false
