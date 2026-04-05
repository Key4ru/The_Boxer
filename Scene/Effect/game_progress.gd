extends Node2D

var unlocked_up_to: int = 0

func unlock_next_level(beaten_index: int) -> void:
	unlocked_up_to = max(unlocked_up_to, beaten_index + 1)
