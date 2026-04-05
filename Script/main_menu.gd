extends Node2D

@onready var sound_hover: AudioStreamPlayer = $Control/SoundHover
@onready var sound_press: AudioStreamPlayer = $Control/SoundPress

func _ready() -> void:
	$Control/Start.mouse_entered.connect(func(): sound_hover.play())
	$Control/Tutorial.mouse_entered.connect(func(): sound_hover.play())
	$Control/Quit.mouse_entered.connect(func(): sound_hover.play())
	pass  # Nothing needed here, SceneTransition handles its own fade

func _on_start_pressed() -> void:
	sound_press.play()
	SceneTransition.change_scene("res://Scene/Levels/level_select.tscn")

func _on_tutorial_pressed() -> void:
	sound_press.play()
	SceneTransition.change_scene("res://Scene/tutorial.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
