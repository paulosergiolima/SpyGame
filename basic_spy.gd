extends CharacterBody2D
signal playerIsClose(spy)
var bought: bool
var price: int
@export var health = 100
@export var power = 100
@export var defense = 100
const SPEED = 300.0
var battleMode: bool = false
const JUMP_VELOCITY = -400.0
@export var followingPlayer: bool = false


func _physics_process(delta: float) -> void:
	if !battleMode:
		var player = get_tree().get_first_node_in_group("player")
		var playerLocation = player.global_position
		look_at(playerLocation)

		var distancePlayer = global_position.distance_to(playerLocation)

		if followingPlayer and distancePlayer > 200 and !battleMode:
			var direction = global_position.direction_to(playerLocation)
			velocity = direction * SPEED
		elif distancePlayer < 150:
			velocity = Vector2.ZERO

		move_and_slide()
	
		
func updateHealth():
	$Health.text = str(health)
	if health <= 0:
		queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if !followingPlayer:
		$Price.visible = true
	pass # Replace with function body.


func _on_area_2d_body_exited(body: Node2D) -> void:
	$Price.visible = false
	pass # Replace with function body.
