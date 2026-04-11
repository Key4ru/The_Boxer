extends CanvasLayer

@onready var yu_bar = $YuHealthBar
@onready var takeda_bar = $TakedaHealthBar

var yu = null
var takeda = null
var max_health = 50

func _ready():
	yu = get_tree().get_first_node_in_group("player")
	takeda = get_tree().get_first_node_in_group("enemy")

	yu_bar.stop()
	takeda_bar.stop()

func _process(_delta):
	if yu != null:
		update_bar(yu_bar, yu.health)

	if takeda != null:
		update_bar(takeda_bar, takeda.health)

func update_bar(bar, health):
	var total_frames = bar.sprite_frames.get_frame_count("default")

	health = clamp(health, 0, max_health)

	var ratio = float(health) / max_health
	var frame = int((1.0 - ratio) * (total_frames - 1))

	bar.frame = frame
