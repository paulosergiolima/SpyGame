extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_door_area_entered(area: Area2D) -> void:
	var spies:  = get_tree().get_nodes_in_group("allies")
	var positions = get_tree().get_nodes_in_group("positions")
	for n in spies.size():
		#spies[n].battleMode = true;
		spies[n].global_position = positions[n].global_position
	
	pass # Replace with function body.
