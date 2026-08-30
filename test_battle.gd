extends Node2D

signal turn_finished
signal player_lost
signal player_won
signal moneyChanged(money)

var chosenAlly = 0
var playerTurn: bool = false
var currentSpy
@export var current_level: int = 1
@export var base_room_budget: int = 10
@export var room_budget: int = 100
var room_spend
const MIN_ENEMY_BUDGET_RATIO := 0.15

const DEFECTION_CHANCE := 0.3
const PAYMENT_RATE := 0.5
var in_shop_phase: bool = false
var chosenSpyIndex: int = 0

var player_scene = preload("res://player.tscn")
var spy_scene = preload("res://basic_spy.tscn")
var enemy_scene = preload("res://basic_enemy.tscn")

var freePosition

var lostState = false
func begin_new_room() -> void:
	room_spend = 0
	room_budget = base_room_budget + ((current_level - 1) * 150)

func _ready() -> void:
	var variables = $"/root/PlayerVariables"
	begin_new_room()
	build_room_from_budget()

	var spies = get_tree().get_nodes_in_group("allies")
	var positions = get_tree().get_nodes_in_group("positions")
	for n in spies.size():
		spies[n].battleMode = true
		spies[n].global_position = positions[n].global_position
		reserve_position_for_unit(spies[n], positions[n])
		spies[n].stopHover()
		spies[n].velocity = Vector2.ZERO

	combatLoop()

func clear_room_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			release_position_for_unit(enemy) 
			enemy.queue_free()

func build_room_from_budget() -> void:
	clear_room_enemies()
	var enemy_slots = get_tree().get_nodes_in_group("enemyPositions")
	var min_enemy_cost = int(room_budget * MIN_ENEMY_BUDGET_RATIO)
	for slot in enemy_slots:
		var remaining = room_budget - room_spend
		if remaining < min_enemy_cost:
			break
		var enemy_cost: int = randi_range(3, room_budget - room_spend)
		var enemy = createEnemy(enemy_cost)
		enemy.global_position = slot.global_position
		enemy.add_to_group("enemies")
		reserve_position_for_unit(enemy, slot)
		add_child(enemy)
		room_spend_enemy(enemy_cost)

func reserve_position_for_unit(unit, position) -> void:
	if not is_instance_valid(unit) or position == null:
		return
	unit.set_meta("assigned_position", position)
	position.taken = true

func release_position_for_unit(unit) -> void:
	if not is_instance_valid(unit):
		return
	if unit.has_meta("assigned_position"):
		var position = unit.get_meta("assigned_position")
		if is_instance_valid(position):
			position.taken = false
		unit.remove_meta("assigned_position")

func cleanup_dead_allies() -> void:
	for ally in get_tree().get_nodes_in_group("allies"):
		if not is_instance_valid(ally) or ally.health > 0:
			continue
		release_position_for_unit(ally)
		ally.remove_from_group("allies")
		ally.queue_free()

func advance_to_next_room() -> void:
	var variables = $"/root/PlayerVariables"
	variables.reward(45 * current_level)
	moneyChanged.emit(variables.money)
	complete_room()
	reset_payments_for_new_room()
	enter_shop_phase()
	print("Sala vencida. Próximo nível: ", current_level)
	print("Orçamento da próxima sala: ", room_budget)
	
func reset_payments_for_new_room() -> void:
	for ally in get_tree().get_nodes_in_group("allies"):
		if is_instance_valid(ally):
			ally.paid = false
			ally.inPayingMode()

func enter_shop_phase() -> void:
	in_shop_phase = true
	chosenSpyIndex = 0
	playerTurn = false
	print("Fase de pagamento: pague seus aliados e aperte 'start_combat' para continuar")

func _input(event: InputEvent) -> void:
	if lostState:
		if event.is_action_pressed("restart"):
			restart_game()
		return
	if in_shop_phase:
		handle_shop_input(event)
		return
	if not playerTurn:
		return
	var playerSize = get_tree().get_nodes_in_group("allies").size()
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		playerTurn = false
		return
	chosenAlly = clamp(chosenAlly, 0, enemies.size() - 1)
	var chosenEnemy = enemies[chosenAlly]

	if event.is_action_pressed("up"):
		chosenEnemy.global_rotation = PI / 2
		goUp(enemies.size())
	elif event.is_action_pressed("down"):
		chosenEnemy.global_rotation = PI / 2
		goDown(enemies.size())
	elif event.is_action_pressed("attack"):
		print("Poder do current : ", currentSpy.power, "  Defesa do inimigo: ", chosenEnemy.defense)
		currentSpy.playAttack()
		var dano = currentSpy.power * (100.0 / (100.0 + chosenEnemy.defense))
		chosenEnemy.health -= clampi(dano, 0, 1000)
		chosenEnemy.updateHealth()
		chosenEnemy.global_rotation = PI / 2
		playerTurn = false
		# Remove from the group BEFORE emitting, so combatLoop (which resumes
		# synchronously insidef emit()) sees accurate group membership.
		if chosenEnemy.health <= 0:
			release_position_for_unit(chosenEnemy)
			chosenEnemy.remove_from_group("enemies")
			chosenEnemy.queue_free()
		turn_finished.emit()
		return
	elif event.is_action_pressed("buySpy") and playerSize < 4:
		var variables = $"/root/PlayerVariables"
		
		freePosition = null
		if not variables.can_afford_player(chosenEnemy.price):
			print("Você não tem dinheiro suficiente")
			return
		for position in get_tree().get_nodes_in_group("positions"):
			print(position.taken)
			if !position.taken:
				freePosition = position
				break
		if freePosition == null:
			return
		variables.spend_player(chosenEnemy.price)
		moneyChanged.emit(variables.money)
		var new_spy = spy_scene.instantiate()
		new_spy.random = false
		new_spy.health = chosenEnemy.health
		new_spy.power = chosenEnemy.power
		new_spy.defense = chosenEnemy.defense
		reserve_position_for_unit(new_spy, freePosition)
		new_spy.global_position = freePosition.global_position
		new_spy.battleMode = true
		new_spy.add_to_group("allies")
		add_child(new_spy)
		chosenEnemy.remove_from_group("enemies")
		chosenEnemy.queue_free()
		playerTurn = false
		turn_finished.emit()
		return
	elif event.is_action_pressed("buySpy") and playerSize >= 4:
		return

	enemies = get_tree().get_nodes_in_group("enemies")
	if chosenAlly < enemies.size():
		enemies[chosenAlly].global_rotation = 0

func handle_shop_input(event: InputEvent) -> void:
	var allies = get_tree().get_nodes_in_group("allies")
	if allies.is_empty():
		start_next_combat()
		return
	chosenSpyIndex = clamp(chosenSpyIndex, 0, allies.size() - 1)
	var selected = allies[chosenSpyIndex]

	if event.is_action_pressed("up"):
		selected.stopHover()
		if chosenSpyIndex != 0:
			chosenSpyIndex -= 1
	elif event.is_action_pressed("down"):
		selected.stopHover()
		if chosenSpyIndex != allies.size() - 1:
			chosenSpyIndex += 1
	elif event.is_action_pressed("pay"):
		if selected.paid:
			return
		var variables = $"/root/PlayerVariables"
		var cost = int(selected.price * PAYMENT_RATE)
		if not variables.can_afford_player(cost):
			print("Você não tem dinheiro suficiente para pagar esse aliado")
			return
		variables.spend_player(cost)
		moneyChanged.emit(variables.money)
		selected.paid = true
		selected.gotPaid()
	elif event.is_action_pressed("start_combat"):
		start_next_combat()

	allies = get_tree().get_nodes_in_group("allies")
	if chosenSpyIndex < allies.size():
		allies[chosenSpyIndex].playHover()

func start_next_combat() -> void:
	in_shop_phase = false
	build_room_from_budget()
	print("Próximo nível: ", current_level)
	print("Orçamento da próxima sala: ", room_budget)
	combatLoop()

func allyAttack(ally) -> void:
	currentSpy = ally
	chosenAlly = 0
	playerTurn = true

func goUp(enemiesCount: int) -> void:
	if chosenAlly != 0:
		chosenAlly -= 1

func goDown(enemiesCount: int) -> void:
	if chosenAlly != enemiesCount - 1:
		chosenAlly += 1

func combatLoop() -> void:
	while true:
		cleanup_dead_allies()
		var allies = get_tree().get_nodes_in_group("allies")
		var enemies = get_tree().get_nodes_in_group("enemies")

		if allies.is_empty():
			player_lost.emit()
			return

		var combatants = []
		combatants.append_array(allies)
		combatants.append_array(enemies)
		combatants.shuffle()

		for unit in combatants:
			if not is_instance_valid(unit):
				continue
			if unit.health <= 0:
				if unit.is_in_group("allies"):
					release_position_for_unit(unit)
					unit.remove_from_group("allies")
					unit.queue_free()
				continue
			if get_tree().get_nodes_in_group("allies").is_empty():
				player_lost.emit()
				return

			if unit.is_in_group("allies"):
				if get_tree().get_nodes_in_group("enemies").is_empty():
					continue
				if try_defect(unit):
					continue
				unit.playHover()
				allyAttack(unit)
				await turn_finished
				if get_tree().get_nodes_in_group("enemies").is_empty():
					player_won.emit()
					return
			else:
				unit.attack()
				cleanup_dead_allies()

func try_defect(ally) -> bool:
	if ally.paid:
		return false
	if not has_free_enemy_slot():
		return false
	if randf() < DEFECTION_CHANCE:
		defect_ally_to_enemy(ally)
		return true
	return false

func _on_player_won() -> void:
	advance_to_next_room()

func defect_ally_to_enemy(ally) -> void:
	var free_slot = null
	for slot in get_tree().get_nodes_in_group("enemyPositions"):
		if not slot.taken:
			free_slot = slot
			break
	if free_slot == null:
		return  # segurança extra — não deveria cair aqui já que checamos antes

	release_position_for_unit(ally)
	ally.remove_from_group("allies")

	var betrayer = enemy_scene.instantiate()
	betrayer.health = ally.health
	betrayer.power = ally.power
	betrayer.defense = ally.defense
	betrayer.global_position = free_slot.global_position
	betrayer.add_to_group("enemies")
	add_child(betrayer)
	betrayer.recalculate_price()
	reserve_position_for_unit(betrayer, free_slot)

	ally.queue_free()
	print("Um aliado não pago desertou para o inimigo!")

func _on_money_changed(money: Variant) -> void:
	$CurrentMoney.text = "Money: " + str(money)

func room_can_support_enemy(enemy_cost: int) -> bool:
	return room_spend + enemy_cost <= room_budget

func room_spend_enemy(enemy_cost: int) -> bool:
	if not room_can_support_enemy(enemy_cost):
		return false
	room_spend += enemy_cost
	return true

func complete_room() -> void:
	current_level += 1
	base_room_budget += 10
	room_budget = base_room_budget + ((current_level - 1) * 150)
	room_spend = 0

func createEnemy(budget: int):
	var enemy = enemy_scene.instantiate()
	var a = randi_range(1, budget - 2)
	var b = randi_range(1, budget - a - 1)
	var c = budget - a - b
	enemy.power = a
	enemy.defense = c
	enemy.health = b
	return enemy

func _on_player_lost() -> void:
	lostState = true
	$Lost.visible = true
	pass # Replace with function body.

func has_free_enemy_slot() -> bool:
	for slot in get_tree().get_nodes_in_group("enemyPositions"):
		if not slot.taken:
			return true
	return false

func restart_game():
	var variables = $"/root/PlayerVariables"
	if variables.has_method("reset"):
		variables.reset()
	get_tree().reload_current_scene()
