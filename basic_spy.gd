extends CharacterBody2D
signal playerIsClose(spy)
var bought: bool
var price: int
const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var followingPlayer: bool = false


func _physics_process(delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	var playerLocation = player.global_position

	look_at(playerLocation)

	var distancePlayer = global_position.distance_to(playerLocation)

	if followingPlayer and distancePlayer > 200:
		var direction = global_position.direction_to(playerLocation)
		velocity = direction * SPEED
	elif distancePlayer < 150:
		velocity = Vector2.ZERO

	move_and_slide()
	
		



func _on_area_2d_body_entered(body: Node2D) -> void:
	if !followingPlayer:
		$Label.visible = true
	pass # Replace with function body.


func _on_area_2d_body_exited(body: Node2D) -> void:
	$Label.visible = false
	pass # Replace with function body.
