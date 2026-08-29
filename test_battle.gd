extends Node2D

signal turn_finished
signal player_lost
signal player_won
signal moneyChanged(money)


var chosenAlly = 0
var playerTurn: bool = false
var currentSpy
@export var current_level: int = 1
@export var base_room_budget: int = 100
@export var room_budget: int = 200
var room_spend

var player_scene = preload("res://player.tscn")
var spy_scene = preload("res://basic_spy.tscn")
var enemy_scene = preload("res://basic_enemy.tscn")

var freePosition

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
		spies[n].rotation = 0
		spies[n].velocity = Vector2.ZERO

	combatLoop()

func clear_room_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			enemy.queue_free()

func build_room_from_budget() -> void:
	clear_room_enemies()
	var enemy_slots = get_tree().get_nodes_in_group("enemyPositions")
	for slot in enemy_slots:
		if room_spend >= room_budget:
			break
		var enemy_cost: int = randi_range(3, room_budget - room_spend)
		var enemy = createEnemy(enemy_cost)
		enemy.global_position = slot.global_position
		enemy.add_to_group("enemies")
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
	variables.reward(100 * current_level)
	moneyChanged.emit(variables.money)
	complete_room()
	build_room_from_budget()
	print("Sala vencida. Próximo nível: ", current_level)
	print("Orçamento da próxima sala: ", room_budget)

func _input(event: InputEvent) -> void:
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
		var dano = currentSpy.power * (100.0 / (100.0 + chosenEnemy.defense))
		chosenEnemy.health -= clampi(dano, 0, 1000)
		chosenEnemy.updateHealth()
		chosenEnemy.global_rotation = PI / 2
		playerTurn = false
		# Remove from the group BEFORE emitting, so combatLoop (which resumes
		# synchronously inside emit()) sees accurate group membership.
		if chosenEnemy.health <= 0:
			chosenEnemy.remove_from_group("enemies")
			chosenEnemy.queue_free()
		turn_finished.emit()
		return
	elif event.is_action_pressed("buySpy") and playerSize < 4:
		print(chosenEnemy.price)
		var variables = $"/root/PlayerVariables"
		if not variables.can_afford_player(chosenEnemy.price):
			print("Você não tem dinheiro suficiente")
			return
		variables.spend_player(chosenEnemy.price)
		moneyChanged.emit(variables.money)
		var new_spy = spy_scene.instantiate()
		new_spy.health = chosenEnemy.health
		new_spy.power = chosenEnemy.power
		new_spy.defense = chosenEnemy.defense
		freePosition = null
		for position in get_tree().get_nodes_in_group("positions"):
			if !position.taken:
				freePosition = position
				break
		if freePosition == null:
			return
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
				unit.global_rotation = 90
				allyAttack(unit)
				await turn_finished
				if is_instance_valid(unit):
					unit.global_rotation = 0
				if get_tree().get_nodes_in_group("enemies").is_empty():
					player_won.emit()
			else:
				unit.attack()
				cleanup_dead_allies()


func _on_player_won() -> void:
	advance_to_next_room()


func _on_money_changed(money: Variant) -> void:
	$CurrentMoney.text = "Dinheiro: " + str(money)

func room_can_support_enemy(enemy_cost: int) -> bool:
	return room_spend + enemy_cost <= room_budget

func room_spend_enemy(enemy_cost: int) -> bool:
	if not room_can_support_enemy(enemy_cost):
		return false
	room_spend += enemy_cost
	return true

func complete_room() -> void:
	current_level += 1
	base_room_budget += 100
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
