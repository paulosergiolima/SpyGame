extends Node2D


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
		print(n)
		spies[n].battleMode = true;
		spies[n].global_position = positions[n].global_position
		spies[n].rotation = 0
		spies[n].velocity = Vector2.ZERO
	var enemySpies = get_tree().get_nodes_in_group("enemies")
	enemySpies[0].attack()
	enemySpies[1].attack()
	enemySpies[2].attack()
	enemySpies[3].attack()
	
	
	pass # Replace with function body.
