extends CharacterBody2D
signal playerIsClose(spy)
var bought: bool
@export var price: int = 100
@export var health = 100
@export var power = 120
@export var defense = 100
@export var random: bool = true
const SPEED = 300.0
var battleMode: bool = false
const JUMP_VELOCITY = -400.0
@export var followingPlayer: bool = false

func _ready() -> void:
	if random:
		health = (randi_range(0,100) + randi_range(0,100) + randi_range(0,100)) / 3
		power = (randi_range(0,100) + randi_range(0,100) + randi_range(0,100)) / 3
		defense = (randi_range(0, 100) + randi_range(0, 100) + randi_range(0,100)) / 3
		price = health/3 + power/3 + defense/3
	$Health.text = str(health)	
	$Power.text = str(power)
	$Defense.text = str(defense)
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
