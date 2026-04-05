extends CharacterBody2D

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sound_whoosh: AudioStreamPlayer2D = $SoundWhoosh
@onready var sound_hit_light: AudioStreamPlayer2D = $SoundHitLight
@onready var sound_hit_heavy: AudioStreamPlayer2D = $SoundHitHeavy
@onready var sound_footstep: AudioStreamPlayer2D = $SoundFootstep
@export var hit_effect_scene: PackedScene

const SPEED = 175.0
const LIGHT_PUNCH_DAMAGE = 2
const HEAVY_PUNCH_DAMAGE = 4
const HEALTH_MAX = 50
const LIGHT_PUNCH_COOLDOWN = 3
const HEAVY_PUNCH_COOLDOWN = 6
const FOOTSTEP_INTERVAL: float = 0.5

var is_attacking: bool = false
var is_dead: bool = false
var health: int = HEALTH_MAX
var light_punch_timer: float = 0.0
var heavy_punch_timer: float = 0.0
var footstep_timer: float = 0.0

func _ready():
	add_to_group("player")
	anim_player.animation_finished.connect(_on_animation_finished)
	anim_player.play("idle")

func _physics_process(delta):
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	light_punch_timer = max(light_punch_timer - delta, 0.0)
	heavy_punch_timer = max(heavy_punch_timer - delta, 0.0)
	footstep_timer = max(footstep_timer - delta, 0.0)

	if is_attacking:
		velocity.x = 0
	else:
		handle_movement(delta)
		handle_attack_input()
	move_and_slide()

func handle_movement(delta):
	var direction = Input.get_axis("backward", "forward")
	if direction != 0:
		var anim_to_play = "forward" if direction > 0 else "backward"
		if animated_sprite.animation != anim_to_play:
			animated_sprite.play(anim_to_play)
		velocity.x = direction * SPEED
		if footstep_timer <= 0.0:
			footstep_timer = FOOTSTEP_INTERVAL
			sound_footstep.play()
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		footstep_timer = 0.0
		if is_on_floor():
			animated_sprite.play("idle")

func handle_attack_input():
	if is_dead:
		return
	if Input.is_action_just_pressed("Attack_Light"):
		if light_punch_timer <= 0.0:
			start_attack("punch_light")
	elif Input.is_action_just_pressed("Attack_Heavy"):
		if heavy_punch_timer <= 0.0:
			start_attack("punch_heavy")

func start_attack(attack_name: String):
	if is_dead:
		return
	is_attacking = true
	velocity.x = 0
	sound_whoosh.play()
	if attack_name == "punch_light":
		light_punch_timer = LIGHT_PUNCH_COOLDOWN
	elif attack_name == "punch_heavy":
		heavy_punch_timer = HEAVY_PUNCH_COOLDOWN
	anim_player.play(attack_name)

func _on_animation_finished(anim_name: String):
	if anim_name in ["punch_light", "punch_heavy"]:
		is_attacking = false
		animated_sprite.play("idle")

# --- HIT DETECTION ---
func _on_light_punch_body_entered(body):
	_handle_hit(body, $"Light Punch/CollisionShape2D".global_position, LIGHT_PUNCH_DAMAGE, "light")

func _on_heavy_punch_body_entered(body):
	_handle_hit(body, $"Heavy Punch/CollisionShape2D".global_position, HEAVY_PUNCH_DAMAGE, "heavy")

func _handle_hit(body, hit_pos: Vector2, damage: int, punch_type: String):
	if body.is_in_group("enemy"):
		spawn_hit_effect(hit_pos)
		if punch_type == "light":
			sound_hit_light.play()
		else:
			sound_hit_heavy.play()
		if body.has_method("take_damage"):
			body.take_damage(damage)

func spawn_hit_effect(hit_pos: Vector2):
	if hit_effect_scene:
		var effect = hit_effect_scene.instantiate()
		get_tree().current_scene.add_child(effect)
		effect.global_position = hit_pos

# --- DAMAGE & DEATH ---
func take_damage(amount: int):
	if is_dead:
		return
	health -= amount
	health = clamp(health, 0, HEALTH_MAX)
	print("Yu: took %d damage → %d/%d HP" % [amount, health, HEALTH_MAX])
	if health <= 0:
		die()

func die():
	if is_dead:
		return
	is_dead = true
	is_attacking = false
	velocity = Vector2.ZERO
	for shape in find_children("*", "CollisionShape2D"):
		shape.set_deferred("disabled", true)
	anim_player.stop()
	animated_sprite.play("dead")
	print("Yu: defeated!")
	KOScreen.trigger(true, "res://Scene/Levels/level_select.tscn")
