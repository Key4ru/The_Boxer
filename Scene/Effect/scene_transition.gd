extends CanvasLayer

@onready var overlay: ColorRect = $ColorRect

var duration: float = 0.5  # seconds for fade in/out

func _ready():
	overlay.color = Color(0, 0, 0, 0)  # Start fully transparent
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block clicks

# Call this to switch scenes with a fade
func change_scene(path: String):
	await fade_out()
	get_tree().change_scene_to_file(path)
	await fade_in()

func fade_out():
	# Fade from transparent to black
	var tween = create_tween()
	tween.tween_property(overlay, "color", Color(0, 0, 0, 1), duration)
	await tween.finished

func fade_in():
	# Fade from black to transparent
	var tween = create_tween()
	tween.tween_property(overlay, "color", Color(0, 0, 0, 0), duration)
	await tween.finished
