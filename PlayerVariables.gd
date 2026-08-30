extends Node

@export var money: int = 100

func can_afford_player(cost: int) -> bool:
	return money >= cost

func spend_player(cost: int) -> bool:
	if not can_afford_player(cost):
		return false
	money -= cost
	return true

func reward(amount: int) -> void:
	money += max(0, amount)
	
func reset() -> void:
	money = 100
