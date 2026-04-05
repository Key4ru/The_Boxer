extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_area: Area2D = $HitArea
@onready var hit_label: Label = get_tree().get_root().get_node("Quest1/CanvasLayer/HitLabel")

var is_hit: bool = false
var hit_cooldown: float = 0.4
var hit_timer: float = 0.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

var hit_count: int = 0
var hit_goal: int = 15
var quest_complete: bool = false

func _ready():
	animated_sprite.play("idle")
	hit_area.area_entered.connect(_on_hit_area_area_entered)
	hit_label.text = "0 / %d" % hit_goal  # Set starting text

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	move_and_slide()

func _process(delta):
	if is_hit:
		hit_timer -= delta
		if hit_timer <= 0.0:
			is_hit = false
			animated_sprite.play("idle")

func _on_hit_area_area_entered(area: Area2D):
	if is_hit:
		return

	var source = area.get_parent()
	if not is_instance_valid(source):
		return

	if "is_attacking" in source and source.is_attacking:
		trigger_hit()
	elif source.has_node("AnimationPlayer"):
		var anim_player = source.get_node("AnimationPlayer")
		if anim_player.current_animation in ["punch_light", "punch_heavy"]:
			trigger_hit()

func trigger_hit():
	if quest_complete:
		return

	is_hit = true
	hit_timer = hit_cooldown
	animated_sprite.play("hit")

	hit_count += 1
	hit_label.text = "%d / %d" % [hit_count, hit_goal]  # ← updates label

	if hit_count >= hit_goal:
		quest_complete = true
		hit_label.text = "DONE!"
		on_quest_complete()

func on_quest_complete():
	print("Quest Complete!")
	await get_tree().create_timer(1.5).timeout
	SceneTransition.change_scene("res://Scene/Levels/level_2.tscn")
