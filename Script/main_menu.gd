extends Node2D

func _ready() -> void:
	pass  # Nothing needed here, SceneTransition handles its own fade

func _on_start_pressed() -> void:
	SceneTransition.change_scene("res://Scene/Levels/level_select.tscn")

func _on_tutorial_pressed() -> void:
	SceneTransition.change_scene("res://Scene/tutorial.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
