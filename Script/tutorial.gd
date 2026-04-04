extends Node2D

func _ready() -> void:
	pass

func _on_back_pressed() -> void:
	SceneTransition.change_scene("res://Scene/main_menu.tscn")
