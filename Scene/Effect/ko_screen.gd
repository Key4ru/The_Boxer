# ko_screen.gd
extends CanvasLayer

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var next_scene: String = ""

func _ready():
	hide()

func trigger(won: bool, scene_path: String):
	next_scene = scene_path  # Store where to go after
	show()
	await get_tree().create_timer(1.5).timeout
	animated_sprite.play("ko")
	await animated_sprite.animation_finished
	await get_tree().create_timer(1.5).timeout
	SceneTransition.change_scene(next_scene)
