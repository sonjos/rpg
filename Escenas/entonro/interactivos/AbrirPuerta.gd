extends Node3D

@onready var animation_player: AnimationPlayer = $Door_1_Flat2/AnimationPlayer

# Añadimos las referencias a los nodos de audio (asegúrate de crear dos nodos AudioStreamPlayer3D hijos en tu escena)
@onready var sonido_abrir: AudioStreamPlayer3D = $SonidoAbrir
@onready var sonido_cerrar: AudioStreamPlayer3D = $SonidoCerrar

var jugador_cerca: bool = false
var puerta_abierta: bool = false

func _ready() -> void:
	# Conectamos la señal del AnimationPlayer para saber cuándo termina una animación
	animation_player.animation_finished.connect(_on_animation_finished)

func _unhandled_input(event: InputEvent) -> void:
	if jugador_cerca and event.is_action_pressed("Interactuar"):
		if not puerta_abierta:
			print("Abriendo puerta...")
			animation_player.speed_scale = 1.0 # Velocidad normal hacia delante
			animation_player.play("Abrir_puerta")
			
			# Reproducir sonido de apertura
			if sonido_abrir:
				sonido_abrir.play()
				
			puerta_abierta = true

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "Abrir_puerta" and puerta_abierta:
		print("Cerrando puerta automáticamente...")
		animation_player.speed_scale = 1.0 # Velocidad normal
		animation_player.play("Cerrar_puerta")
		
		# Reproducir sonido de cierre
		if sonido_cerrar:
			sonido_cerrar.play()
			
		puerta_abierta = false
	elif anim_name == "Cerrar_puerta":
		# Esto asegura que cuando termine de cerrarse, todo se resetea bien
		print("Puerta cerrada.")

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		jugador_cerca = true

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		jugador_cerca = false

func _on_area_3d_area_entered(area: Area3D) -> void:
	pass
