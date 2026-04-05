class_name J
extends CharacterBody2D

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var light_punch_area: Area2D = $"Light Punch"
@onready var heavy_punch_area: Area2D = $"Heavy Punch"
@onready var reaction_timer: Timer = $ReactionTimer
@onready var sound_whoosh: AudioStreamPlayer2D = $SoundWhoosh
@onready var sound_hit_light: AudioStreamPlayer2D = $SoundHitLight
@onready var sound_hit_heavy: AudioStreamPlayer2D = $SoundHitHeavy
@onready var sound_footstep: AudioStreamPlayer2D = $SoundFootstep
@export var hit_effect_scene: PackedScene
@export var player: CharacterBody2D

const SPEED = 175.0
const HEALTH_MAX = 50
const LIGHT_PUNCH_DAMAGE = 6
const HEAVY_PUNCH_DAMAGE = 12
const LIGHT_PUNCH_COOLDOWN = 0.2
const HEAVY_PUNCH_COOLDOWN = 0.7
const DIST_CHASE: float = 350.0
const DIST_FAR: float = 80.0
const DIST_IDEAL: float = 60.0
const DIST_CLOSE: float = 40.0
const STAGGER_MIN: float = 0.2
const STAGGER_MAX: float = 0.45
const FOOTSTEP_INTERVAL: float = 0.5

enum State { IDLE, FORWARD_WALK, BACKWARD_WALK, PUNCH }
enum Phase { IDLE, RETREAT, AGGRESSIVE }

var current_state: State = State.IDLE
var current_phase: Phase = Phase.IDLE
var health: int = HEALTH_MAX
var is_dead: bool = false
var player_is_dead: bool = false
var doing_combo: bool = false
var combo_count: int = 0
var max_combo: int = 3
var light_punch_timer: float = 0.0
var heavy_punch_timer: float = 0.0
var stagger_timer: float = 0.0
var decision_timer: float = 0.0
var current_attack: String = ""
var hit_registered: bool = false
var punish_window: float = 0.0
var player_was_punching: bool = false
var consecutive_hits: int = 0
var consecutive_misses: int = 0
var locked_dir: float = 1.0
var is_stepping_back: bool = false
var stepback_timer: float = 0.0
var footstep_timer: float = 0.0
var defeated = false

func _ready() -> void:
	add_to_group("enemy")
	anim_player.animation_finished.connect(_on_animation_finished)
	if reaction_timer:
		reaction_timer.one_shot = true
	if anim_player.has_animation("idle"):
		anim_player.play("idle")
	else:
		animated_sprite.play("idle")
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	if not player:
		push_error("J: No player found in group 'player'!")
	else:
		print("J: found player → ", player.name)

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if _is_player_dead():
		velocity = Vector2.ZERO
		current_state = State.IDLE
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")
		move_and_slide()
		return
	if not is_on_floor():
		velocity += get_gravity() * delta

	light_punch_timer = max(light_punch_timer - delta, 0.0)
	heavy_punch_timer = max(heavy_punch_timer - delta, 0.0)
	decision_timer = max(decision_timer - delta, 0.0)
	stepback_timer = max(stepback_timer - delta, 0.0)
	footstep_timer = max(footstep_timer - delta, 0.0)

	if punish_window > 0.0:
		punish_window -= delta
	if stagger_timer > 0.0:
		stagger_timer -= delta
		velocity.x = move_toward(velocity.x, 0, SPEED * delta * 4.0)
		move_and_slide()
		return
	if player == null:
		move_and_slide()
		return

	var dir: float = sign(player.global_position.x - global_position.x)
	var dist: float = abs(player.global_position.x - global_position.x)

	if dist > DIST_CLOSE:
		locked_dir = dir
	if current_state != State.PUNCH:
		animated_sprite.flip_h = locked_dir < 0

	var player_punching: bool = _is_player_punching()
	if player_punching and not player_was_punching:
		punish_window = 0.45
	player_was_punching = player_punching

	if current_state == State.PUNCH:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta * 4.0)
		move_and_slide()
		update_animations()
		return
	if stepback_timer > 0.0:
		velocity.x = -locked_dir * SPEED * 1.5
		current_state = State.BACKWARD_WALK
		move_and_slide()
		update_animations()
		return
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		if col.get_collider() != player:
			continue
		stepback_timer = 0.35
		velocity.x = -locked_dir * SPEED * 1.5
		current_state = State.BACKWARD_WALK
		move_and_slide()
		update_animations()
		return
	if dist < DIST_CLOSE:
		stepback_timer = 0.35
		velocity.x = -locked_dir * SPEED * 1.5
		current_state = State.BACKWARD_WALK
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
		if randf() < 0.008:
			_enter_punch(_pick_punch())
	elif dist > DIST_IDEAL:
		if punish_window > 0.0:
			punish_window = 0.0
			_enter_punch(_pick_punch())
		elif decision_timer <= 0.0:
			_mid_range_decision(dir, delta)
	else:
		if punish_window > 0.0:
			punish_window = 0.0
			_enter_punch(_pick_punch())
		elif decision_timer <= 0.0:
			_close_range_decision(dir, delta)

	if is_on_wall() and sign(velocity.x) == dir:
		velocity.x = -dir * SPEED * 0.8
		current_state = State.BACKWARD_WALK
		reaction_timer.start(randf_range(0.3, 0.6))

	move_and_slide()
	update_animations()

func _is_player_dead() -> bool:
	if player == null:
		return true
	if "is_dead" in player:
		return player.is_dead
	return false

func _mid_range_decision(dir: float, delta: float) -> void:
	decision_timer = randf_range(0.25, 0.5)
	var r: float = randf()
	if r < 0.60:
		_enter_punch(_pick_punch())
	elif r < 0.80:
		_start_combo()
	elif r < 0.92:
		velocity.x = -dir * SPEED * 0.5
		current_state = State.BACKWARD_WALK
		reaction_timer.start(randf_range(0.3, 0.5))
	else:
		velocity.x = 0
		current_state = State.IDLE
		reaction_timer.start(randf_range(0.2, 0.4))

func _close_range_decision(_dir: float, _delta: float) -> void:
	decision_timer = randf_range(0.15, 0.3)
	var r: float = randf()
	if r < 0.65:
		_start_combo()
	elif r < 0.90:
		_enter_punch(_pick_punch())
	else:
		velocity.x = -sign(player.global_position.x - global_position.x) * SPEED * 0.8
		current_state = State.BACKWARD_WALK
		reaction_timer.start(randf_range(0.2, 0.4))

func _pick_punch() -> String:
	if heavy_punch_timer <= 0.0 and randf() < 0.45:
		return "punch_heavy"
	return "punch_light"

func _enter_punch(attack_name: String = "punch_light") -> void:
	if not anim_player.has_animation(attack_name):
		print("DEBUG ERROR: AnimationPlayer missing: ", attack_name)
		return
	current_state = State.PUNCH
	current_attack = attack_name
	hit_registered = false
	velocity.x = 0
	sound_whoosh.play()
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
	if not "is_attacking" in player:
		return false
	return player.is_attacking

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
			if footstep_timer <= 0.0:
				footstep_timer = FOOTSTEP_INTERVAL
				sound_footstep.play()
		State.BACKWARD_WALK:
			if animated_sprite.animation != "backward":
				animated_sprite.play("backward")
			if footstep_timer <= 0.0:
				footstep_timer = FOOTSTEP_INTERVAL
				sound_footstep.play()

func _on_animation_finished(anim_name: String) -> void:
	if anim_name in ["punch_light", "punch_heavy"]:
		if hit_registered:
			consecutive_hits += 1
			consecutive_misses = 0
		else:
			consecutive_misses += 1
			consecutive_hits = 0
		if doing_combo and combo_count < max_combo - 1:
			combo_count += 1
			await get_tree().create_timer(0.07).timeout
			_enter_punch("punch_light")
		else:
			doing_combo = false
			combo_count = 0
			hit_registered = false
			current_state = State.IDLE
			current_attack = ""
			current_phase = Phase.IDLE
			reaction_timer.start(randf_range(0.18, 0.38))

func scan_light_hit() -> void:
	if not hit_registered:
		_scan_hit(light_punch_area, LIGHT_PUNCH_DAMAGE)

func scan_heavy_hit() -> void:
	if not hit_registered:
		_scan_hit(heavy_punch_area, HEAVY_PUNCH_DAMAGE)

func _scan_hit(area: Area2D, damage: int) -> void:
	var bodies = area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player"):
			hit_registered = true
			spawn_hit_effect(body.global_position)
			if damage == LIGHT_PUNCH_DAMAGE:
				sound_hit_light.play()
			else:
				sound_hit_heavy.play()
			if body.has_method("take_damage"):
				body.take_damage(damage)
			return

func _on_light_punch_body_entered(body) -> void:
	if current_state == State.PUNCH and current_attack == "punch_light" and not hit_registered:
		if body.is_in_group("player"):
			hit_registered = true
			spawn_hit_effect(body.global_position)
			sound_hit_light.play()
			if body.has_method("take_damage"):
				body.take_damage(LIGHT_PUNCH_DAMAGE)

func _on_heavy_punch_body_entered(body) -> void:
	if current_state == State.PUNCH and current_attack == "punch_heavy" and not hit_registered:
		if body.is_in_group("player"):
			hit_registered = true
			spawn_hit_effect(body.global_position)
			sound_hit_heavy.play()
			if body.has_method("take_damage"):
				body.take_damage(HEAVY_PUNCH_DAMAGE)

func spawn_hit_effect(hit_pos: Vector2) -> void:
	if hit_effect_scene == null:
		return
	var effect = hit_effect_scene.instantiate()
	get_tree().current_scene.add_child(effect)
	effect.global_position = hit_pos
	if effect is AnimatedSprite2D:
		if effect.sprite_frames != null:
			var anim_list = effect.sprite_frames.get_animation_names()
			if anim_list.size() > 0:
				effect.play(anim_list[0])
	elif effect is AnimationPlayer:
		var anim_list = effect.get_animation_list()
		if anim_list.size() > 0:
			effect.play(anim_list[0])

func take_damage(amount: int) -> void:
	if is_dead:
		return
	health -= amount
	health = clamp(health, 0, HEALTH_MAX)
	print("J: took %d damage → %d/%d HP" % [amount, health, HEALTH_MAX])
	current_state = State.IDLE
	current_phase = Phase.RETREAT
	current_attack = ""
	hit_registered = false
	doing_combo = false
	combo_count = 0
	velocity.x = 0
	decision_timer = 0.0
	if reaction_timer:
		reaction_timer.stop()
	stagger_timer = randf_range(STAGGER_MIN, STAGGER_MAX)
	anim_player.stop()
	animated_sprite.play("idle")
	if health <= 0:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	current_state = State.IDLE
	doing_combo = false
	for shape in find_children("*", "CollisionShape2D"):
		shape.set_deferred("disabled", true)
	anim_player.stop()
	animated_sprite.play("dead")
	print("DEBUG: J defeated!")
	GameProgress.unlock_next_level(3)
	KOScreen.trigger(true, "res://Scene/Levels/ending.tscn") 
