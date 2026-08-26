extends Node2D
var chosenAlly = 0
var lockedTurn = false
var playerTurn: bool = false
var currentSpy
signal turn_finished
signal player_lost
signal player_won

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_door_area_entered(area: Area2D) -> void:
	$Camera2D.enabled = true
	var player = get_tree().get_nodes_in_group("player")[0]
	player.queue_free()
	
	var spies:  = get_tree().get_nodes_in_group("allies")
	var positions = get_tree().get_nodes_in_group("positions")
	for n in spies.size():
		spies[n].battleMode = true;
		spies[n].global_position = positions[n].global_position
		spies[n].rotation = 0
		spies[n].velocity = Vector2.ZERO
	var enemySpies = get_tree().get_nodes_in_group("enemies")
	$Door.queue_free()
	
	combatLoop()
	
func _input(event: InputEvent) -> void:
	var chosenEnemy = get_tree().get_nodes_in_group("enemies")[chosenAlly]
	if playerTurn:
		if event.is_action_pressed("up"):
			chosenEnemy.global_rotation = PI/2
			goUp()
		elif event.is_action_pressed("down"):
			chosenEnemy.global_rotation = PI/2
			goDown()
		elif event.is_action_pressed("buySpy"):
			chosenEnemy.health = chosenEnemy.health - (currentSpy.power - chosenEnemy.defense)
			playerTurn = false
			turn_finished.emit()
			chosenEnemy.updateHealth()
			
		chosenEnemy = get_tree().get_nodes_in_group("enemies")[chosenAlly]
		chosenEnemy.global_rotation = 0

func allyAttack(chosenCharacter):
	currentSpy = get_tree().get_nodes_in_group("allies")[chosenCharacter]
	chosenAlly = 0
	playerTurn = true
	
	
	

func goUp():
	if chosenAlly != 0:
		chosenAlly = chosenAlly - 1
		return
	return
func goDown():
	if chosenAlly != (get_tree().get_nodes_in_group("allies").size() - 1):
		chosenAlly = chosenAlly + 1
		return
	return
func combatLoop():
	var allies = get_tree().get_nodes_in_group("allies")
	var alliesSize = allies.size()
	var enemySize = get_tree().get_nodes_in_group("enemies").size()
	if alliesSize <= 0:
		player_lost.emit()
	if enemySize <= 0:
		player_won.emit()
		
	
	
	print("Size of allies", alliesSize)
	var turnOrder = range(alliesSize + enemySize)
	turnOrder.shuffle()
	for n in turnOrder:
		print(n)
		#Isso significa que é um aliado
		if n < alliesSize:
			print("We got ally turn")
			allies[n].global_rotation = 90
			allyAttack(n)
			await turn_finished
			allies[n].global_rotation = 0
			pass
		else:
			print("We got enemy turn")
			var enemySpies = get_tree().get_nodes_in_group("enemies")
			enemySpies[n - alliesSize].attack()
			pass
	combatLoop()
			
	
