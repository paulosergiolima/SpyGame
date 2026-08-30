extends AnimatedSprite2D

@export var health: int = 100
@export var power: int = 120
@export var defense: int = 100
@export var price: int = 100

func recalculate_price() -> void:
	price = int((health / 3.0) + (power / 3.0) + (defense / 3.0))


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#health = (randi_range(0, 100) + randi_range(0, 100) + randi_range(0,100)) / 3
	#power = (randi_range(0, 100) + randi_range(0, 100) + randi_range(0,100)) / 3
	#defense = (randi_range(0, 100) + randi_range(0, 100) + randi_range(0,100)) / 3
	#recalculate_price()
	if health == 0:
		health = 1
	recalculate_price()
	$Health.text = str(health)
	$Price.text = str(price)
	$Attack.text = str(power)
	$Defense.text = str(defense)
	play("default")
	pass # Replace with function body.

func updateHealth():
	$Health.text = str(health)
	recalculate_price()
	if health <= 0:
		remove_from_group("enemies")
		queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func attack():
	var playerUnits = get_tree().get_nodes_in_group("allies")
	var randomNumber = randi_range(0, playerUnits.size() - 1)
	var currentEnemy = playerUnits[randomNumber]
	var dano = power * (100.0 / (100.0 + playerUnits[randomNumber].defense))
	playerUnits[randomNumber].health = currentEnemy.health - clampi(dano,0,1000)
	playerUnits[randomNumber].updateHealth()
	
func playAimed() -> void:
	play("aimed")

func stopAimed() -> void:
	play("default")
	
