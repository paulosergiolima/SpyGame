extends CharacterBody2D
signal playerIsClose(spy)
var bought: bool
var price: int
@export var health = 100
@export var power = 120
@export var defense = 100
@export var random: bool = true
const SPEED = 300.0
var battleMode: bool = false
const JUMP_VELOCITY = -400.0
var paid: bool = true
@export var followingPlayer: bool = false

func inPayingMode():
	$Paid.text = "Not yet paid"
	$Paid.visible = true

func gotPaid():
	$Paid.visible = false

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

func playHover():
	$Sprite2D.play("hover")
func playAttack():
	$Sprite2D.play("shooting")
func stopHover() -> void:
	$Sprite2D.play("default") 


func _on_sprite_2d_animation_finished() -> void:
	
	pass # Replace with function body.


func _on_sprite_2d_animation_looped() -> void:
	print("this is a tst")
	if $Sprite2D.animation == "shooting":
		print("this is a tst yall")
		$Sprite2D.play("default")
	pass # Replace with function body.
