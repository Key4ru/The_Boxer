class_name takada
extends CharacterBody2D

const SPEED = 175.0

enum State { IDLE, BACKWARD_WALK, FORWARD_WALK, PUNCH }
var current_state = State.IDLE

# ✅ Check your scene tree: Is it named 'AnimatedSprite2D' or 'AnimatedSprite2D2'?
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D 

func _ready() -> void:
	# 🔗 CRITICAL: This connects the signal so the punch actually ends
	sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	# 1. Apply Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0

	# 2. Get Input
	var direction := Input.get_axis("ui_left", "ui_right")

	# 3. State Logic
	if Input.is_action_just_pressed("Attack") and can_attack():
		enter_punch_state()
	elif current_state != State.PUNCH:
		if direction > 0:
			current_state = State.FORWARD_WALK
			sprite.flip_h = true 
		elif direction < 0:
			current_state = State.BACKWARD_WALK
			sprite.flip_h = true # ✅ FIXED: Now faces Left
		else:
			current_state = State.IDLE

	# 4. Movement
	if current_state != State.PUNCH:
		velocity.x = direction * SPEED
	else:
		# Slide to a stop during punch
		velocity.x = move_toward(velocity.x, 0, SPEED)

	update_animations()
	move_and_slide()

func can_attack() -> bool:
	return current_state != State.PUNCH

func enter_punch_state() -> void:
	current_state = State.PUNCH
	sprite.play("punch")

func update_animations() -> void:
	# 🛑 Prevent walking animations from overriding the punch
	if current_state == State.PUNCH:
		return

	match current_state:
		State.IDLE:
			sprite.play("idle") 
		State.FORWARD_WALK:
			sprite.play("forward_walk")
		State.BACKWARD_WALK:
			sprite.play("backward_walk")

func _on_animation_finished() -> void:
	# Reset state once the punch animation completes
	if sprite.animation == "punch":
		current_state = State.IDLE

# Fixed typo from "enit" to "emit"
func on_emit_damage(damage_receiver: Area2D) -> void:
	print("Hit: ", damage_receiver.name)
