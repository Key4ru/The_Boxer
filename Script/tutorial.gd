extends Node2D

@onready var sound_hover: AudioStreamPlayer = $Control/SoundHover
@onready var sound_press: AudioStreamPlayer = $Control/SoundPress

func _ready() -> void:
	$Control/Back.mouse_entered.connect(func(): sound_hover.play())
	pass

func _on_back_pressed() -> void:
	sound_press.play()
	SceneTransition.change_scene("res://Scene/main_menu.tscn")
