extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var closeToSpy: bool = false
var spy


func _physics_process(delta: float) -> void:
	# Add the gravity.

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	var directionY := Input.get_axis("up","down")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	if directionY:
		velocity.y = directionY * SPEED
	else:
		velocity.y = directionY * SPEED
	if closeToSpy and Input.is_action_pressed("buySpy"):
		spy.followingPlayer = true
		print("The player clicked space")
		

	move_and_slide()


func _on_area_2d_area_entered(area: Area2D) -> void:
	spy = area.get_parent()
	closeToSpy = true
	print("The player has gotten close to the spy")
	
	pass # Replace with function body.
