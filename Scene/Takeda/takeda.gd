class_name BasicTakeda
extends CharacterBody2D

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var light_punch_area: Area2D = $"Light Punch"
@onready var heavy_punch_area: Area2D = $"Heavy Punch"
@onready var reaction_timer: Timer = $ReactionTimer
@export var hit_effect_scene: PackedScene
@export var player: CharacterBody2D

const SPEED = 175.0
const HEALTH_MAX = 50
const LIGHT_PUNCH_DAMAGE = 2
const HEAVY_PUNCH_DAMAGE = 4
const LIGHT_PUNCH_COOLDOWN = 1.5
const HEAVY_PUNCH_COOLDOWN = 3.0

const DIST_CHASE: float = 350.0
const DIST_FAR: float = 80.0
const DIST_IDEAL: float = 45.0
const DIST_CLOSE: float = 20.0

enum State { IDLE, FORWARD_WALK, BACKWARD_WALK, PUNCH }

var current_state: State = State.IDLE
var health: int = HEALTH_MAX

var doing_combo: bool = false
var combo_count: int = 0
var max_combo: int = 3

var light_punch_timer: float = 0.0
var heavy_punch_timer: float = 0.0

var current_attack: String = ""
var hit_registered: bool = false

var punish_window: float = 0.0
var player_was_punching: bool = false

func _ready():
	add_to_group("enemy")
	anim_player.animation_finished.connect(_on_animation_finished)
	anim_player.play("idle")

	if player == null:
		player = get_tree().get_first_node_in_group("player")

	if not player:
		print("DEBUG ERROR: No player found!")
	else:
		print("DEBUG: BasicTakeda found player: ", player.name)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	light_punch_timer = max(light_punch_timer - delta, 0.0)
	heavy_punch_timer = max(heavy_punch_timer - delta, 0.0)

	if punish_window > 0.0:
		punish_window -= delta

	if player == null:
		move_and_slide()
		return

	var dir: float = sign(player.global_position.x - global_position.x)
	var dist: float = abs(player.global_position.x - global_position.x)

	var player_punching: bool = _is_player_punching()
	if player_punching and not player_was_punching:
		punish_window = 0.45
	player_was_punching = player_punching

	if current_state == State.PUNCH:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta * 4.0)
		move_and_slide()
		update_animations()
		return

	if reaction_timer and not reaction_timer.is_stopped():
		velocity.x = move_toward(velocity.x, 0, SPEED * delta * 3.0)
		current_state = State.IDLE
		update_animations()
		move_and_slide()
		return

	if dist > DIST_CHASE:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		current_state = State.IDLE
	elif dist > DIST_FAR:
		velocity.x = dir * SPEED
		current_state = State.FORWARD_WALK
		if randf() < 0.003:
			_enter_punch(_pick_punch())
	elif dist > DIST_IDEAL:
		if punish_window > 0.0:
			punish_window = 0.0
			_enter_punch(_pick_punch())
		else:
			_mid_range_decision(dir, delta)
	elif dist > DIST_CLOSE:
		if punish_window > 0.0:
			punish_window = 0.0
			_enter_punch(_pick_punch())
		else:
			_close_range_decision(dir, delta)
	else:
		velocity.x = -dir * SPEED * 1.1
		current_state = State.BACKWARD_WALK
		reaction_timer.start(0.1)

	move_and_slide()
	update_animations()

func _mid_range_decision(dir: float, delta: float) -> void:
	var r: float = randf()
	if r < 0.35:
		_enter_punch(_pick_punch())
	elif r < 0.55:
		_start_combo()
	elif r < 0.75:
		velocity.x = -dir * SPEED * 0.3
		current_state = State.BACKWARD_WALK
		reaction_timer.start(randf_range(0.1, 0.2))
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta * 2.0)
		current_state = State.IDLE
		reaction_timer.start(randf_range(0.2, 0.4))

func _close_range_decision(_dir: float, _delta: float) -> void:
	var r: float = randf()
	if r < 0.5:
		_start_combo()
	elif r < 0.75:
		_enter_punch(_pick_punch())
	else:
		velocity.x = -sign(player.global_position.x - global_position.x) * SPEED * 0.6
		current_state = State.BACKWARD_WALK
		reaction_timer.start(0.15)

func _pick_punch() -> String:
	if heavy_punch_timer <= 0.0 and randf() < 0.3:
		return "punch_heavy"
	return "punch_light"

func _enter_punch(attack_name: String = "punch_light") -> void:
	if not anim_player.has_animation(attack_name):
		print("DEBUG ERROR: AnimationPlayer missing: ", attack_name)
		return

	print("DEBUG: Enemy starting: ", attack_name)
	current_state = State.PUNCH
	current_attack = attack_name
	hit_registered = false
	velocity.x = 0

	if attack_name == "punch_light":
		light_punch_timer = LIGHT_PUNCH_COOLDOWN
	elif attack_name == "punch_heavy":
		heavy_punch_timer = HEAVY_PUNCH_COOLDOWN

	anim_player.play(attack_name)

func _start_combo() -> void:
	if doing_combo:
		_enter_punch("punch_light")
		return
	doing_combo = true
	combo_count = 0
	_enter_punch("punch_light")

func _is_player_punching() -> bool:
	if player == null:
		return false
	if not "current_state" in player:
		return false
	return player.current_state == player.State.PUNCH_LIGHT

func update_animations() -> void:
	if current_state == State.PUNCH:
		return
	match current_state:
		State.IDLE:
			if animated_sprite.animation != "idle":
				animated_sprite.play("idle")
		State.FORWARD_WALK:
			if animated_sprite.animation != "forward":
				animated_sprite.play("forward")
		State.BACKWARD_WALK:
			if animated_sprite.animation != "backward":
				animated_sprite.play("backward")

func _on_animation_finished() -> void:
	var anim_name = anim_player.current_animation

	if anim_name in ["punch_light", "punch_heavy"]:
		if doing_combo and combo_count < max_combo - 1:
			combo_count += 1
			await get_tree().create_timer(0.08).timeout
			_enter_punch("punch_light")
		else:
			doing_combo = false
			combo_count = 0
			hit_registered = false
			current_state = State.IDLE
			current_attack = ""
			reaction_timer.start(randf_range(0.2, 0.45))

# --- HIT SCAN ---
# In AnimationPlayer add a Call Method Track at the impact frame:
# punch_light → scan_light_hit
# punch_heavy → scan_heavy_hit

func scan_light_hit() -> void:
	print("DEBUG: scan_light_hit called")
	if not hit_registered:
		_scan_hit(light_punch_area, LIGHT_PUNCH_DAMAGE)

func scan_heavy_hit() -> void:
	print("DEBUG: scan_heavy_hit called")
	if not hit_registered:
		_scan_hit(heavy_punch_area, HEAVY_PUNCH_DAMAGE)

func _scan_hit(area: Area2D, damage: int) -> void:
	var bodies = area.get_overlapping_bodies()
	print("DEBUG: Bodies in punch area: ", bodies.size())
	for body in bodies:
		if body.is_in_group("player"):
			print("DEBUG: HIT CONFIRMED on player!")
			hit_registered = true
			spawn_hit_effect(area.global_position)
			if body.has_method("take_damage"):
				body.take_damage(damage)
			return

# --- SIGNAL FALLBACK ---
func _on_light_punch_body_entered(body) -> void:
	if current_state == State.PUNCH and current_attack == "punch_light" and not hit_registered:
		if body.is_in_group("player"):
			print("DEBUG: light punch fallback hit!")
			hit_registered = true
			spawn_hit_effect(light_punch_area.global_position)
			if body.has_method("take_damage"):
				body.take_damage(LIGHT_PUNCH_DAMAGE)

func _on_heavy_punch_body_entered(body) -> void:
	if current_state == State.PUNCH and current_attack == "punch_heavy" and not hit_registered:
		if body.is_in_group("player"):
			print("DEBUG: heavy punch fallback hit!")
			hit_registered = true
			spawn_hit_effect(heavy_punch_area.global_position)
			if body.has_method("take_damage"):
				body.take_damage(HEAVY_PUNCH_DAMAGE)

func spawn_hit_effect(hit_pos: Vector2) -> void:
	if hit_effect_scene:
		var effect = hit_effect_scene.instantiate()
		get_tree().current_scene.add_child(effect)
		effect.global_position = hit_pos
		if effect is AnimatedSprite2D:
			effect.play("default")
		print("DEBUG: Hit effect spawned at: ", hit_pos)
	else:
		print("DEBUG ERROR: No hit_effect_scene assigned!")

# --- DAMAGE & DEATH ---
func take_damage(amount: int) -> void:
	health -= amount
	print("DEBUG: Enemy took ", amount, " damage. HP: ", health, "/", HEALTH_MAX)

	# Reset all attack state so AI doesn't get stuck
	current_state = State.IDLE
	hit_registered = false
	current_attack = ""
	doing_combo = false
	combo_count = 0
	velocity.x = 0
	anim_player.play("idle")

	if reaction_timer and reaction_timer.is_stopped():
		reaction_timer.start(randf_range(0.3, 0.6))

	if health <= 0:
		die()

func die() -> void:
	print("DEBUG: Enemy defeated!")
	queue_free()
