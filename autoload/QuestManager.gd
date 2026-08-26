# res://autoload/QuestManager.gd
extends Node

signal mision_actualizada

var mision_activa: String = ""
var descripcion_mision: String = ""
var cantidad_requerida: int = 0
var item_objetivo_nombre_ref: String = "" 
var mision_cantidad_actual: int = 0
var mision_aceptada: bool = false
var mision_completada: bool = false

# Índice de la misión actual del 1 al 20
var indice_mision_actual: int = 1

# Catálogo completo de las 20 misiones
const CATALOGO_MISIONES = {
	1: {"titulo": "Caza de Lobos", "desc": "Consigue los restos requeridos.", "Req": 3, "item_nombre": "Hueso de lobo", "oro": 150, "exp": 120, "dialogo": "Los lobos del bosque están descontrolados por la corrupción. ¿Aceptas cazaros y traerme sus restos?", "aceptar": "¡Perfecto! Ve al bosque y tráeme los huesos de lobo."},
	2: {"titulo": "Rastreo en la Niebla Azul", "desc": "Recolecta pieles densas de la zona.", "Req": 4, "item_nombre": "Piel Azulada", "oro": 200, "exp": 150, "dialogo": "Las hojas azuladas del bosque ocultan criaturas rápidas. Necesito pieles para resistir el frío.", "aceptar": "Ve y consigue esas pieles azuladas."},
	3: {"titulo": "Insumos para el Pueblo Natal", "desc": "Reúne mineral de cobre para Eldrin.", "Req": 5, "item_nombre": "Mineral de Cobre", "oro": 180, "exp": 140, "dialogo": "El herrero Eldrin necesita materiales resistentes para forjar acero. ¿Me ayudas?", "aceptar": "Tráeme el mineral de cobre cuanto antes."},
	4: {"titulo": "El Veneno de las Raíces", "desc": "Obtén muestras de esporas toxicas.", "Req": 2, "item_nombre": "Espora Toxica", "oro": 220, "exp": 160, "dialogo": "Las raíces gigantes segregan toxinas. Tráeme muestras para estudiarlas.", "aceptar": "Cuidado con el veneno en las raíces."},
	5: {"titulo": "Limpieza de Bandidos Desertores", "desc": "Recupera insignias de los seguidores de Malakor.", "Req": 4, "item_nombre": "Insignia del Sol Corrupto", "oro": 250, "exp": 200, "dialogo": "Seguidores de Malakor merodean cerca del valle. Deshazte de ellos.", "aceptar": "Recupera sus insignias del sol corrupto."},
	6: {"titulo": "Acechadores de la Oscuridad", "desc": "Caza merodeadores nocturnos.", "Req": 6, "item_nombre": "Colmillo de Sombra", "oro": 300, "exp": 220, "dialogo": "Conforme nos acercamos a las ruinas, los monstruos son más agresivos. Cázalos.", "aceptar": "Tráeme los colmillos de sombra."},
	7: {"titulo": "Reliquias de las Ruinas Antiguas", "desc": "Consigue un fragmento de estatuaria.", "Req": 1, "item_nombre": "Fragmento de Estatuaria", "oro": 350, "exp": 280, "dialogo": "En las estatuas rotas de los reyes hay fragmentos sagrados. Tráeme uno.", "aceptar": "Busca bien entre los escombros de Kaelen."},
	8: {"titulo": "El Altar Profanado", "desc": "Recolecta caparazones resilientes.", "Req": 5, "item_nombre": "Caparazón Resiliente", "oro": 280, "exp": 210, "dialogo": "El altar profanado emana energía purificable con polvos de insectos.", "aceptar": "Consigue esos caparazones resilientes."},
	9: {"titulo": "Vigilancia al Guardián Caído", "desc": "Reúne almas menores encadenadas.", "Req": 3, "item_nombre": "Alma Menor Encadenada", "oro": 400, "exp": 300, "dialogo": "El Guardián Caído protege algo grande. Debemos debilitar a sus esbirros.", "aceptar": "Derrota a sus almas menores."},
	10: {"titulo": "Preparativos para el Mar", "desc": "Consigue pescado abisal para el viaje.", "Req": 4, "item_nombre": "Pescado Abisal", "oro": 450, "exp": 350, "dialogo": "Para cruzar hacia las tierras heladas con Jorah, necesitamos provisiones.", "aceptar": "Consigue el pescado abisal en la costa."},
	11: {"titulo": "La Brújula de Plata", "desc": "Encuentra la brújula en las minas.", "Req": 1, "item_nombre": "Brújula de Plata", "oro": 600, "exp": 400, "dialogo": "Jorah no zarpará sin una brújula de plata de las minas. ¿Puedes traérsela?", "aceptar": "Búsquela en los túneles costeros."},
	12: {"titulo": "Helado y Letal", "desc": "Recolecta cristales térmicos.", "Req": 5, "item_nombre": "Cristal Térmico", "oro": 500, "exp": 380, "dialogo": "En la cripta el frío provoca maldiciones. Necesitamos cristales térmicos.", "aceptar": "Consigue los cristales para contrarrestar el hielo."},
	13: {"titulo": "Espectros de la Cripta", "desc": "Obtén ectoplasma gélido.", "Req": 6, "item_nombre": "Ectoplasma Gélido", "oro": 550, "exp": 420, "dialogo": "Los pasillos de hielo están llenos de almas en pena. Acaba con ellas.", "aceptar": "Extrae el ectoplasma gélido."},
	14: {"titulo": "El Secreto de Sariel", "desc": "Consigue runas anti-embrujo.", "Req": 2, "item_nombre": "Runa Anti-Embrujo", "oro": 700, "exp": 500, "dialogo": "Sariel usa magia que induce embrujos. Tráeme runas de protección.", "aceptar": "Consigue las runas de protección."},
	15: {"titulo": "Mecanismos Ocultos de Hielo", "desc": "Reúne engranajes congelados.", "Req": 4, "item_nombre": "Engranaje Congelado", "oro": 480, "exp": 360, "dialogo": "Para activar las palancas de la cripta, requerimos engranajes especiales.", "aceptar": "Busca los engranajes congelados."},
	16: {"titulo": "Ríos de Lava y Calor Extremo", "desc": "Obtén escamas de magma.", "Req": 5, "item_nombre": "Escama de Magma", "oro": 800, "exp": 600, "dialogo": "La fortaleza se alza sobre un volcán. Necesitamos escamas ignífugas.", "aceptar": "Consigue las escamas de magma."},
	17: {"titulo": "Estandartes del Eclipse", "desc": "Destruye retazos del eclipse.", "Req": 3, "item_nombre": "Retazo del Eclipse", "oro": 850, "exp": 650, "dialogo": "Los seguidores portan estandartes malditos. Quema su tela.", "aceptar": "Tráeme los retazos del eclipse."},
	18: {"titulo": "En busca de la DragonStone", "desc": "Encuentra una piedra de dragón pura.", "Req": 1, "item_nombre": "DragonStone", "oro": 1500, "exp": 900, "dialogo": "Los comerciantes pagan fortunas por reliquias volcánicas puras.", "aceptar": "Consigue la DragonStone."},
	19: {"titulo": "Forjando el Destino", "desc": "Recolecta metal estelar.", "Req": 3, "item_nombre": "Metal Estelar", "oro": 1200, "exp": 800, "dialogo": "Para debilitar a Malakor, necesitamos fragmentos de metal estelar.", "aceptar": "Reúne el metal estelar."},
	20: {"titulo": "La Última Cacería", "desc": "Obtén núcleos de sombra pura.", "Req": 10, "item_nombre": "Núcleo de Sombra Pura", "oro": 2500, "exp": 1500, "dialogo": "El ejército final del Señor Oscuro se agrupa. Demuestra tu valor.", "aceptar": "Acaba con ellos y tráeme los núcleos."}
}

func _ready() -> void:
	if InventarioManager.has_signal("inventario_actualizado"):
		InventarioManager.inventario_actualizado.connect(actualizar_progreso)

func aceptar_mision(nombre: String, desc: String, cantidad: int, nombre_item: String) -> void:
	mision_activa = nombre
	descripcion_mision = desc
	cantidad_requerida = cantidad
	item_objetivo_nombre_ref = nombre_item
	mision_aceptada = true
	mision_completada = false
	actualizar_progreso()

func actualizar_progreso() -> void:
	if not mision_aceptada or mision_completada:
		return
		
	var conteo: int = 0
	# Comparamos ignorando mayúsculas/minúsculas para evitar fallos de escritura
	var objetivo_limpio = item_objetivo_nombre_ref.strip_edges().to_lower()
	
	for slot in InventarioManager.inventario:
		if slot and slot.has("item") and slot["item"] != null:
			var item_en_slot = slot["item"]
			if "nombre" in item_en_slot:
				var nombre_slot_limpio = str(item_en_slot.nombre).strip_edges().to_lower()
				if nombre_slot_limpio == objetivo_limpio:
					conteo += slot["cantidad"]
				
	mision_cantidad_actual = conteo
	mision_actualizada.emit()

func completar_mision() -> void:
	mision_completada = true
	mision_actualizada.emit()

func obtener_mision_actual() -> Dictionary:
	if CATALOGO_MISIONES.has(indice_mision_actual):
		return CATALOGO_MISIONES[indice_mision_actual]
	return {}

func avanzar_siguiente_mision() -> void:
	indice_mision_actual += 1
	mision_aceptada = false
	mision_completada = false
	mision_activa = ""
	descripcion_mision = ""
	cantidad_requerida = 0
	item_objetivo_nombre_ref = ""
	mision_cantidad_actual = 0
