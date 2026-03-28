class_name Takada
extends CharacterBody2D

const SPEED = 175.0

# Added BACKWARD_WALK to match the AI
enum State { IDLE, FORWARD_WALK, BACKWARD_WALK, PUNCH }
var current_state = State.IDLE

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D 

func _ready() -> void:
	# Connect the signal so we know when the punch ends
	sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	# 1. Apply Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 2. Handle Input & States
	var direction := Input.get_axis("ui_left", "ui_right")
	
	# We only allow movement/flipping if not currently punching
	if current_state != State.PUNCH:
		if Input.is_action_just_pressed("Attack"):
			enter_punch_state()
		elif direction != 0:
			# Determine if walking Forward or Backward
			# If direction is Right and we face Right -> Forward
			# If direction is Left and we face Right -> Backward
			if (direction > 0 and !sprite.flip_h) or (direction < 0 and sprite.flip_h):
				current_state = State.FORWARD_WALK
			else:
				current_state = State.BACKWARD_WALK
				
			velocity.x = direction * SPEED
			
			# OPTIONAL: Remove the line below if you want Takada 
			# to ONLY flip when the player presses a "Turn" button.
			sprite.flip_h = (direction < 0)
		else:
			current_state = State.IDLE
			velocity.x = move_toward(velocity.x, 0, SPEED)
	else:
		# Friction: Slide to a stop during the punch
		velocity.x = move_toward(velocity.x, 0, SPEED * delta * 5)

	move_and_slide()
	update_animations()

func enter_punch_state() -> void:
	current_state = State.PUNCH
	# We play it here to ensure it starts instantly
	sprite.play("punch")

func update_animations() -> void:
	# If we are punching, don't let the walk/idle animations override it
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
	if sprite.animation == "punch":
		current_state = State.IDLE

func on_emit_damage(damage_receiver: Area2D) -> void:
	print("Hit: ", damage_receiver.name)
