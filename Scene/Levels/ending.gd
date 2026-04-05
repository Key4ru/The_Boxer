extends Node2D

@onready var yu: AnimatedSprite2D = $Yu
@onready var sound_applause: AudioStreamPlayer = $SoundApplause
@onready var sound_bgm: AudioStreamPlayer = $SoundBGM

func _ready():
	sound_bgm.play()
	yu.play("idle")
	
	await get_tree().create_timer(5.0).timeout
	yu.play("raising_hand")
	sound_applause.play()
	
	await get_tree().create_timer(5.0).timeout
	SceneTransition.change_scene("res://Scene/main_menu.tscn")
