extends Node2D

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Scene/main_menu.tscn")
