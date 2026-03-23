extends Node2D

func _ready() -> void:
	pass



func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Scene/start.tscn")

func _on_tutorial_pressed() -> void:
	get_tree().change_scene_to_file("res://Scene/tutorial.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
