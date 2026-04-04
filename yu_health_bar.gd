extends AnimatedSprite2D

@onready var yu_bar = $YuHealthBar
@onready var takeda_bar = $TakedaHealthBar

var yu
var takeda

var max_health = 50
var total_frames = 26

func _ready():
	yu = get_tree().get_first_node_in_group("player")
	takeda = get_tree().get_first_node_in_group("enemy")

func _process(delta):
	if yu:
		update_bar(yu_bar, yu.health)

	if takeda:
		update_bar(takeda_bar, takeda.health)

func update_bar(bar, health):
	health = clamp(health, 0, max_health)

	var ratio = float(health) / max_health
	var frame = int((1.0 - ratio) * (total_frames - 1))

	bar.frame = frame
