class_name BasicTakeda
extends "res://Script/Takeda/takeda.gd"

@export var player : yu
@onready var reaction_timer: Timer = $ReactionTimer

var is_deciding: bool = false

func _physics_process(delta: float) -> void:
	# 1. Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	if player != null:
		var direction_to_player = sign(player.global_position.x - global_position.x)
		var dist = abs(player.global_position.x - global_position.x)
		
		# 🛑 If punching, just slow down
		if current_state == State.PUNCH:
			velocity.x = move_toward(velocity.x, 0, SPEED * delta)
			return # Exit early so we don't change states mid-punch

		# 🧠 REACTION DELAY LOGIC
		# If the player moves out of the "Sweet Spot", we start a timer before chasing/retreating
		if (dist > 80.0 or dist < 40.0) and not is_deciding and current_state == State.IDLE:
			is_deciding = true
			reaction_timer.start()

		# While the timer is running, Takeda stands still (IDLE)
		if not reaction_timer.is_stopped():
			velocity.x = move_toward(velocity.x, 0, SPEED)
			current_state = State.IDLE
		else:
			# Timer is finished, now he can move!
			is_deciding = false
			
			# 🏃 PLAYER IS FAR AWAY (Was 80, now is 40)
		if dist > 10.0: 
			velocity.x = direction_to_player * SPEED
			current_state = State.FORWARD_WALK
			
		# 🏃 PLAYER IS *TOO* CLOSE (Was 40, now is 20)
		# NOTE: You might not even need this check if Yu is already very close.
		elif dist < 20.0:
			velocity.x = -direction_to_player * (SPEED * 0.4) 
			current_state = State.BACKWARD_WALK
			
		# 👊 PLAYER IS IN PUNCH RANGE (Was 40-80, now is 20-40)
		else:
			# THIS IS WHERE HE PUNCHES
			velocity.x = 0
			enter_punch_state()

	move_and_slide()
	update_animations()

func enter_punch_state() -> void:
	current_state = State.PUNCH
	sprite.play("punch")

# Connect this to your AnimatedSprite2D's animation_finished signal!
func _on_animation_finished() -> void:
	if sprite.animation == "punch":
		current_state = State.IDLE
		# Give him a moment to breathe after punching
		reaction_timer.start()
