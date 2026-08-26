extends Sprite2D

@export var health: int = 100
@export var power: int = 120
@export var defense: int = 100


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func attack():
	var playerUnits = get_tree().get_nodes_in_group("allies")
	var randomNumber = randi_range(0, playerUnits.size() - 1)
	var currentEnemy = playerUnits[randomNumber]
	playerUnits[randomNumber].health = currentEnemy.health - (power - currentEnemy.defense)
	playerUnits[randomNumber].updateHealth()
	
