class_name ItemData
extends Resource

@export_group("Creacion de objetos")
@export var nombre: String = "Objeto"
@export var icono: Texture2D
@export_multiline var descripcion: String = "Descripción del objeto."
@export_enum("Arma", "Armadura", "Consumible", "Clave", "Mochila", "Abalorio", "Misiones") var tipo: int
@export_group ("Comercio")
@export var precio_compra: int = 50
@export var precio_venta: int = 25
# --- VISUAL EN EL MUNDO ---
@export_group("Mundo y Apariencia")
@export var modelo_3d: PackedScene           # El modelo 3D que aparececrá tirado en el suelo o cofre

# --- PROPIEDADES DE INVENTARIO ---
@export_group("Inventario")
@export var es_acumulable: bool = false       # Si se pueden apilar varios en el mismo hueco
@export var cantidad_maxima: int = 99         # Máximo de unidades por casilla

# --- MODIFICADORES DE ESTADÍSTICAS ---
@export_group("Modificadores de Estadísticas")
@export var bonus_fuerza_poder: int = 0         # Daño o fuerza de ataque
@export var bonus_defensa: int = 0             # Reducción de daño / armadura
@export var bonus_agilidad_velocidad: float = 0.0 # Velocidad de movimiento
@export var bonus_saqueo: float = 0.0         # Probabilidad extra de loot / saqueo
@export var cantidad_curacion: int = 0       # Vida que recupera (si es consumible)
@export var es_consumible: bool = false       # Si se gasta al usarlo

# --- NUEVAS PROPIEDADES PARA CONSUMIBLES TEMPORALES ---
@export var es_temporal: bool = false      # Si el efecto dura un tiempo limitado
@export var duracion_efecto: float = 10.0  # Segundos que dura el efecto activo

# --- REQUISITOS DE USO ---
@export_group("Requisitos")
@export var requiere_item: ItemData           # El objeto necesario para usarlo (ej: Flechas)
@export var cantidad_consumida_requisito: int = 1 # Unidades que gasta al usarlo
