extends Node

# Si está en true, el jugador podrá viajar a cualquier sitio directamente para pruebas
@export var debug_desbloquear_todo: bool = true

const ZONAS_MUNDO = {
	"valle_aethelgard": "Valle de Aethelgard",
	"bosque_susurrante": "Bosque Susurrante",
	"ruinas_kaelen": "Ruinas de Kaelen",
	"puerto_bruma": "Puerto Bruma",
	"cripta_helada": "Cripta del Viento Helado",
	"costa_norte": "Costa Norte",
	"fortaleza_obsidiana": "Fortaleza de Obsidiana"
}

var zonas_visitadas: Array[String] = [
	"valle_aethelgard"
]

var zona_actual: String = "valle_aethelgard"

func registrar_visita(id_zona: String) -> void:
	if id_zona in ZONAS_MUNDO and not id_zona in zonas_visitadas:
		zonas_visitadas.append(id_zona)
		print("¡Nueva zona descubierta: ", ZONAS_MUNDO[id_zona], "!")

func ha_visitado_zona(id_zona: String) -> bool:
	# Si el modo de pruebas está activo, devuelve true para cualquier zona
	if debug_desbloquear_todo:
		return true
	return id_zona in zonas_visitadas

func obtener_nombre_zona(id_zona: String) -> String:
	return ZONAS_MUNDO.get(id_zona, "Zona Desconocida")

func cambiar_zona(id_zona: String, nueva_posicion: Vector3, jugador: Node3D) -> void:
	if not ha_visitado_zona(id_zona):
		print("Acceso denegado: El jugador aún no ha visitado la zona: ", id_zona)
		return
	
	zona_actual = id_zona
	if jugador:
		jugador.global_position = nueva_posicion
		print("Teletransporte exitoso a: ", ZONAS_MUNDO.get(id_zona, id_zona))
