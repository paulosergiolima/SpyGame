extends Node2D

signal turn_finished
signal player_lost
signal player_won
signal moneyChanged(money)

var chosenAlly = 0
var playerTurn: bool = false
var currentSpy

var player_scene = preload("res://player.tscn")
var spy_scene = preload("res://basic_spy.tscn")

var freePosition

func _ready() -> void:
	$Camera2D.enabled = true
	#var player = get_tree().get_nodes_in_group("player")[0]
	#player.visible = false
	#player.queue_free()

	var spies = get_tree().get_nodes_in_group("allies")
	var positions = get_tree().get_nodes_in_group("positions")
	for n in spies.size():
		spies[n].battleMode = true
		spies[n].global_position = positions[n].global_position
		reserve_position_for_unit(spies[n], positions[n])
		spies[n].rotation = 0
		spies[n].velocity = Vector2.ZERO

	combatLoop()

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
	

func _input(event: InputEvent) -> void:
	if not playerTurn:
		return
	var playerSize = get_tree().get_nodes_in_group("allies").size()
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
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
		chosenEnemy.health -= clampi((currentSpy.power - chosenEnemy.defense),0,1000)
		chosenEnemy.updateHealth()
		chosenEnemy.global_rotation = PI/2
		playerTurn = false
		enemies = get_tree().get_nodes_in_group("enemies")
		print(enemies)
		if enemies.is_empty():
			print("The player has won")
			player_won.emit()
		turn_finished.emit()
	elif event.is_action_pressed("buySpy") and playerSize < 4:
		print(chosenEnemy.price)
		if ($"/root/PlayerVariables".money < chosenEnemy.price):
			print("You are poor")
			return
		$"/root/PlayerVariables".money -= chosenEnemy.price
		moneyChanged.emit($"/root/PlayerVariables".money)
		
		print(playerSize)
		print("has he bought?")
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
		chosenEnemy.queue_free()
		enemies = get_tree().get_nodes_in_group("enemies")
		print(enemies)
		if enemies.is_empty():
			print("The player has won")
			player_won.emit()
	elif event.is_action_pressed("buySpy") and playerSize >= 4:
		return

	if chosenEnemy.health <= 0:
		chosenEnemy.remove_from_group("enemies")
		chosenEnemy.queue_free()
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
				unit.global_rotation = 90
				allyAttack(unit)
				await turn_finished
				if is_instance_valid(unit):
					unit.global_rotation = 0
			else:
				unit.attack()
				cleanup_dead_allies()


func _on_player_won() -> void:
	print("The player has won")
	var new_player = player_scene.instantiate()
	var allies = get_tree().get_nodes_in_group("allies")
	for spy in allies:
		spy.battleMode = false
		spy.velocity = Vector2.ZERO
	new_player.global_position = $PlayerSpawn.global_position
	new_player.velocity = Vector2.ZERO
	add_child(new_player)
	$Camera2D.enabled = false
	
	pass # Replace with function body.


func _on_money_changed(money: Variant) -> void:
	$CurrentMoney.text = "Dinheiro: " + str(money)
	pass # Replace with function body.
