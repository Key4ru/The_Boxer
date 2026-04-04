extends CanvasLayer

@onready var yu_bar = $YuHealthBar
@onready var aaron_bar = $AaronHealthBar

var yu = null
var aaron = null
var max_health = 50

func _ready():
	print("UI READY")

	yu = get_tree().get_first_node_in_group("player")
	aaron = get_tree().get_first_node_in_group("enemy")

	print("YU:", yu)
	print("AARON:", aaron)

	yu_bar.stop()
	aaron_bar.stop()

func _process(delta):
	if yu != null:
		update_bar(yu_bar, yu.health)

	if aaron != null:
		update_bar(aaron_bar, aaron.health)

func update_bar(bar, health):
	var total_frames = bar.sprite_frames.get_frame_count("default")

	health = clamp(health, 0, max_health)

	var ratio = float(health) / max_health
	var frame = int((1.0 - ratio) * (total_frames - 1))

	bar.frame = frame
