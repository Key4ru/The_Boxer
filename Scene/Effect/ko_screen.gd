extends CanvasLayer

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var music: AudioStreamPlayer = $Music

var next_scene: String = ""

func _ready():
	hide()

func trigger(_won: bool, scene_path: String):
	next_scene = scene_path
	show()

	# Wait 1.5 seconds
	await get_tree().create_timer(1.5).timeout

	# Play music and animation at the same time
	music.play()
	animated_sprite.play("ko")

	# Wait for animation to finish
	await animated_sprite.animation_finished
	await get_tree().create_timer(1.5).timeout

	# Stop music then transition
	music.stop()
	SceneTransition.change_scene(next_scene)
