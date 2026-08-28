extends Sprite2D

@export var health: int = 100
@export var power: int = 120
@export var defense: int = 100
@export var price: int = 100


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health = (randi_range(0, 100) + randi_range(0, 100) + randi_range(0,100)) / 3
	power = (randi_range(0, 100) + randi_range(0, 100) + randi_range(0,100)) / 3
	defense = (randi_range(0, 100) + randi_range(0, 100) + randi_range(0,100)) / 3
	price =  (health / 3) + (power / 3) + (defense / 3)
	$Health.text = str(health)
	pass # Replace with function body.
	
func updateHealth():
	$Health.text = str(health)
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
	playerUnits[randomNumber].health = currentEnemy.health - clampi((power - currentEnemy.defense),0,1000)
	playerUnits[randomNumber].updateHealth()
	
