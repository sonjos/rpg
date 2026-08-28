extends StaticBody3D
class_name CristalPerimetro

@export_group("Identificación")
@export_enum("pilar_guardian", "pilar_sariel", "pilar_malakor") var identificador_pilar: String = "pilar_guardian"

@export_group("Configuración Visual")
## Color del cristal encendido (azul brillante)
@export var color_magia := Color(0.0, 0.83, 1.0)
## Color del cristal apagado (oscuro y desaturado)
@export var color_apagado := Color(0.1, 0.15, 0.2)
@export var intensidad_luz := 3.0

@onready var cristal_mesh: MeshInstance3D = $Cristal
@onready var luz: OmniLight3D = $OmniLight3D

# Control de estado para los gestores de eventos
var esta_encendido: bool = false

func _ready() -> void:
	add_to_group(identificador_pilar)
	add_to_group("cristales_perimetro") # Nos permite gestionarlos todos desde el evento inicial
	
	apagar()
	
	# Comprobación de estado persistente al cargar la partida
	if "jefes_derrotados" in PlayerStats:
		match identificador_pilar:
			"pilar_guardian":
				if PlayerStats.jefes_derrotados.get("guardian_caido", false):
					encender()
			"pilar_sariel":
				if PlayerStats.jefes_derrotados.get("sariel", false):
					encender()
			"pilar_malakor":
				if PlayerStats.jefes_derrotados.get("malakor", false):
					encender()

func encender() -> void:
	esta_encendido = true
	var mat := _obtener_material_unico()
	if mat:
		mat.albedo_color = color_magia
		mat.emission_enabled = true
		mat.emission = color_magia
		mat.emission_energy_multiplier = 3.0

	if luz:
		luz.light_color = color_magia
		luz.light_energy = intensidad_luz

func apagar() -> void:
	esta_encendido = false
	var mat := _obtener_material_unico()
	if mat:
		# Cambiar el color base a un tono oscuro apagado y quitar emisión
		mat.albedo_color = color_apagado
		mat.emission_enabled = false
		mat.emission_energy_multiplier = 0.0

	if luz:
		luz.light_energy = 0.0

# Métodos compatibles con el gestor de eventos
func encender_cristal() -> void:
	encender()

func apagar_cristal() -> void:
	apagar()

func _obtener_material_unico() -> StandardMaterial3D:
	if not cristal_mesh:
		return null
		
	var mat := cristal_mesh.get_surface_override_material(0) as StandardMaterial3D
	if not mat and cristal_mesh.mesh and cristal_mesh.mesh.material:
		mat = cristal_mesh.mesh.material as StandardMaterial3D
		if mat:
			mat = mat.duplicate() as StandardMaterial3D
			cristal_mesh.set_surface_override_material(0, mat)
			
	return mat
