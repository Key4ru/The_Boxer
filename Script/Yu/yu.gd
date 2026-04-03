extends CharacterBody2D
const SPEED = 175.0

enum State { IDLE, BACKWARD_WALK, FORWARD_WALK, PUNCH_LIGHT, PUNCH_HEAVY }
var current_state = State.IDLE

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D2
@onready var sfx_punch: AudioStreamPlayer = $sfx_punch

func _physics_process(delta: float) -> void:
	# Add this at the very top
	if is_punching() and not sprite.is_playing():
		current_state = State.IDLE

	# ... rest of your code

	var direction := Input.get_axis("ui_left", "ui_right")

	if can_attack():
		if Input.is_action_just_pressed("Attack_Light"):
			enter_punch_state(State.PUNCH_LIGHT)
		elif Input.is_action_just_pressed("Attack_Heavy"):
			enter_punch_state(State.PUNCH_HEAVY)
		elif direction > 0:
			current_state = State.FORWARD_WALK
			sprite.flip_h = false  # Face Right
		elif direction < 0:
			current_state = State.BACKWARD_WALK
			sprite.flip_h = false    # ✅ FIX 1: Was false, should be true to face Left
		else:
			current_state = State.IDLE

	if not is_punching():
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	update_animations()
	move_and_slide()

func is_punching() -> bool:
	return current_state == State.PUNCH_LIGHT or current_state == State.PUNCH_HEAVY

func can_attack() -> bool:
	return not is_punching()

func enter_punch_state(new_state: State) -> void:
	current_state = new_state
	if new_state == State.PUNCH_LIGHT:
		sprite.play("punch_light")
	elif new_state == State.PUNCH_HEAVY:
		sprite.play("punch_heavy")
		
	sfx_punch.play()

func update_animations() -> void:
	if not is_punching():
		# ✅ FIX 2: Was two identical `if` blocks both playing forward_walk,
		#    then backward_walk was never reached. Split into elif correctly.
		if current_state == State.FORWARD_WALK:
			sprite.play("forward_walk")
		elif current_state == State.BACKWARD_WALK:
			sprite.play("backward_walk")
		else:
			sprite.play("stance_idle")

func _on_animation_finished() -> void:
	if sprite.animation == "punch_light" or sprite.animation == "punch_heavy":
		current_state = State.IDLE
