extends Control

var current_level = 0
var levels = [
	{"name": "TAKEDA YUTO",        "portrait": preload("res://others/Takeda_Head.png"),    "color": Color(0.27, 0.51, 1.0),         "bg": preload("res://BG/Ring 1.png"), "scene": "res://Scene/Levels/level_1.tscn"},
	{"name": "SANTORINO FABRIZIO", "portrait": preload("res://others/Santorino_Head.png"), "color": Color(0.98, 0.862, 0.366, 1.0), "bg": preload("res://BG/Ring 1.png"), "scene": "res://Scene/Levels/level_2.tscn"},
	{"name": "AARON TIDE",         "portrait": preload("res://others/Aaron_Head.png"),     "color": Color(0.688, 0.655, 0.644, 1.0),"bg": preload("res://BG/Ring 2.png"), "scene": "res://Scene/Levels/level_3.tscn"},
	{"name": "J",                  "portrait": preload("res://others/J_Head.png"),         "color": Color(1.0, 0.288, 0.225, 1.0),  "bg": preload("res://BG/Ring 3.png"), "scene": "res://Scene/Levels/level_4.tscn"},
]

@onready var background     = $TextureRect
@onready var enemy_name     = $EnemyName
@onready var level_label    = $LevelLabel
@onready var btn_left       = $BtnLeft
@onready var btn_right      = $BtnRight
@onready var btn_play       = $BtnPlay
@onready var enemy_portrait = $EnemyPortrait
@onready var lock_icon      = $LockIcon
@onready var sound_hover: AudioStreamPlayer = $SoundHover
@onready var sound_press: AudioStreamPlayer = $SoundPress

func _ready():
	btn_left.pressed.connect(_on_left)
	btn_right.pressed.connect(_on_right)
	btn_play.pressed.connect(_on_play)
	
	btn_left.mouse_entered.connect(func(): sound_hover.play())
	btn_right.mouse_entered.connect(func(): sound_hover.play())
	btn_play.mouse_entered.connect(func(): sound_hover.play())
	$Back.mouse_entered.connect(func(): sound_hover.play())
	
	lock_icon.visible = false
	update_display()

func _on_left():
	sound_press.play()
	current_level -= 1
	update_display()

func _on_right():
	sound_press.play()
	current_level += 1
	update_display()

func _on_play():
	sound_press.play()
	if current_level > GameProgress.unlocked_up_to:
		return
	SceneTransition.change_scene(levels[current_level]["scene"])

func update_display():
	background.texture     = levels[current_level]["bg"]
	enemy_portrait.texture = levels[current_level]["portrait"]
	enemy_name.text        = levels[current_level]["name"]
	enemy_name.remove_theme_color_override("font_color")
	enemy_name.add_theme_color_override("font_color", levels[current_level]["color"])
	enemy_name.add_theme_color_override("font_outline_color", Color(0.085, 0.092, 0.17, 1.0))
	enemy_name.add_theme_constant_override("outline_size", 15)
	level_label.text = "LEVEL " + str(current_level + 1)
	level_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	level_label.add_theme_constant_override("outline_size", 6)
	btn_left.disabled  = current_level == 0
	btn_right.disabled = current_level == levels.size() - 1

	var is_locked = current_level > GameProgress.unlocked_up_to
	btn_play.disabled = is_locked
	lock_icon.visible = is_locked

func _on_back_pressed() -> void:
	sound_press.play()
	SceneTransition.change_scene("res://Scene/main_menu.tscn")
