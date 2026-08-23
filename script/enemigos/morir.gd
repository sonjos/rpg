extends Enemigo_state_machine

@export_group("Recompensas")
@export var experiencia_otorgada: int = 50
@export var monedas_otorgadas: int = 10
@export var tabla_botin: Array[LootEntry] = []
@export_range(0.0, 1.0) var probabilidad_drop_general: float = 0.8
@export var escena_item_drop: PackedScene

func enter(_msg: Dictionary = {}) -> void:
	if character:
		character.velocity = Vector3.ZERO
		state_machine.play_anim("Death")
		
		if PlayerStats.has_method("ganar_experiencia"):
			PlayerStats.ganar_experiencia(experiencia_otorgada)
		
		var bono_saqueo = PlayerStats.saqueo if "saqueo" in PlayerStats else 0.0
		var monedas_finales = int(monedas_otorgadas * (1.0 + (bono_saqueo * 0.05)))
		
		if PlayerStats.has_method("ganar_monedas"):
			PlayerStats.ganar_monedas(monedas_finales)
		
		generar_loot_con_saqueo()
		PlayerStats.reportar_enemigo_muerto()
		
		# Espera 1.2 segundos para reproducir la animación de muerte completa antes de borrar el nodo
		await get_tree().create_timer(1.2).timeout
		if is_instance_valid(character):
			character.queue_free()

func generar_loot_con_saqueo() -> void:
	var saqueo_jugador: float = PlayerStats.saqueo if "saqueo" in PlayerStats else 0.0
	var prob_efectiva: float = clamp(probabilidad_drop_general + (saqueo_jugador * 0.02), 0.0, 1.0)
	
	if tabla_botin.size() == 0 or randf() > prob_efectiva:
		return
	
	var peso_total: float = 0.0
	var pesos_modificados: Array[float] = []
	
	for entrada in tabla_botin:
		if not entrada or not entrada.objeto:
			continue
			
		var peso_base: float = entrada.peso
		var factor_rareza: float = 100.0 / max(peso_base, 1.0)
		var peso_final: float = peso_base + (saqueo_jugador * factor_rareza * 0.5)
		
		pesos_modificados.append(peso_final)
		peso_total += peso_final
			
	if peso_total <= 0.0:
		return

	var numero_azar: float = randf_range(0.0, peso_total)
	var peso_acumulado: float = 0.0
	var item_elegido: Resource = null
	
	var indice_valido: int = 0
	for entrada in tabla_botin:
		if not entrada or not entrada.objeto:
			continue
			
		peso_acumulado += pesos_modificados[indice_valido]
		if numero_azar <= peso_acumulado:
			item_elegido = entrada.objeto
			break
		indice_valido += 1

	if item_elegido:
		if escena_item_drop:
			var drop = escena_item_drop.instantiate()
			character.get_parent().add_child(drop)
			drop.global_position = character.global_position
			if "item_data" in drop:
				drop.item_data = item_elegido
		elif PlayerStats and PlayerStats.has_method("recoger_item"):
			PlayerStats.recoger_item(item_elegido)
