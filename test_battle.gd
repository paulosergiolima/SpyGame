extends Node2D

signal turn_finished
signal player_lost
signal player_won

var chosenAlly = 0
var playerTurn: bool = false
var currentSpy

var player_scene = preload("res://player.tscn")

func _on_door_area_entered(area: Area2D) -> void:
	$Camera2D.enabled = true
	var player = get_tree().get_nodes_in_group("player")[0]
	player.queue_free()

	var spies = get_tree().get_nodes_in_group("allies")
	var positions = get_tree().get_nodes_in_group("positions")
	for n in spies.size():
		spies[n].battleMode = true
		spies[n].global_position = positions[n].global_position
		spies[n].rotation = 0
		spies[n].velocity = Vector2.ZERO

	$Door.queue_free()
	combatLoop()

func _input(event: InputEvent) -> void:
	if not playerTurn:
		return

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
	elif event.is_action_pressed("buySpy"):
		print("Vida passada: ", chosenEnemy.health)
		chosenEnemy.health -= (currentSpy.power - chosenEnemy.defense)
		print("Vida atual depois do ataque: ", chosenEnemy.health)
		chosenEnemy.updateHealth()
		chosenEnemy.global_rotation = PI/2

		if chosenEnemy.health <= 0:
			chosenEnemy.remove_from_group("enemies")
			chosenEnemy.queue_free()

		playerTurn = false
		turn_finished.emit()
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
		var allies = get_tree().get_nodes_in_group("allies")
		var enemies = get_tree().get_nodes_in_group("enemies")

		if allies.is_empty():
			player_lost.emit()
			return
		if enemies.is_empty():
			player_won.emit()
			return

		var combatants = []
		combatants.append_array(allies)
		combatants.append_array(enemies)
		combatants.shuffle()

		for unit in combatants:
			if not is_instance_valid(unit) or unit.health <= 0:
				continue
			if get_tree().get_nodes_in_group("allies").is_empty():
				player_lost.emit()
				return
			if get_tree().get_nodes_in_group("enemies").is_empty():
				player_won.emit()
				return

			if unit.is_in_group("allies"):
				print("We got ally turn")
				unit.global_rotation = 90
				allyAttack(unit)
				await turn_finished
				if is_instance_valid(unit):
					unit.global_rotation = 0
			else:
				print("We got enemy turn")
				unit.attack()


func _on_player_won() -> void:
	add_child(player_scene)
	$Camera2D.enabled = false
	
	pass # Replace with function body.
