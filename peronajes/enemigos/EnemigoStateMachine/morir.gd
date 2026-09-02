# res://states/Muerte.gd
extends State

func enter(_msg: Dictionary = {}) -> void:
	character.velocity = Vector3.ZERO
	state_machine.play_anim("Death")
	
	# Esperar un poco antes de eliminar el enemigo
	await get_tree().create_timer(2.0).timeout
	
	# Entregar recompensas al morir
	_entregar_recompensas()
	
	# Eliminar el enemigo del mundo
	character.queue_free()

func _entregar_recompensas() -> void:
	# Otorgar experiencia
	if state_machine.experiencia_otorgada > 0 and PlayerStats.has_method("ganar_experiencia"):
		PlayerStats.ganar_experiencia(int(state_machine.experiencia_otorgada))
		print("EXP OTORGADA: ", state_machine.experiencia_otorgada)
	
	# Otorgar monedas
	if state_machine.monedas_otorgadas > 0 and PlayerStats.has_method("ganar_monedas"):
		PlayerStats.ganar_monedas(state_machine.monedas_otorgadas)
		print("MONEDAS OTORGADAS: ", state_machine.monedas_otorgadas)
	
	# Procesar loot con peso ponderado
	if state_machine.tabla_botin.size() > 0:
		var total_peso: float = 0.0
		for loot_entry in state_machine.tabla_botin:
			if loot_entry is LootEntry and loot_entry.objeto:
				total_peso += max(1.0, float(loot_entry.peso))
		
		if total_peso > 0.0 and randf() < state_machine.probabilidad_drop_general:
			var ruleta: float = randf() * total_peso
			var acumulado: float = 0.0
			var item_drop = null
			
			for loot_entry in state_machine.tabla_botin:
				if not (loot_entry is LootEntry) or not loot_entry.objeto:
					continue
				acumulado += max(1.0, float(loot_entry.peso))
				if ruleta <= acumulado:
					item_drop = loot_entry.objeto
					break
			
			if item_drop and InventarioManager.has_method("recoger_item"):
				InventarioManager.recoger_item(item_drop)
				print("DROP LOOT: ", item_drop.nombre, " | PESO: ", ruleta, " / ", total_peso)
			elif item_drop:
				print("ERROR: InventarioManager no tiene método recoger_item")
		else:
			print("NO HUBO DROP: probabilidad base = ", state_machine.probabilidad_drop_general)

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	character.move_and_slide()

func handle_input(_event: InputEvent) -> void:
	pass
