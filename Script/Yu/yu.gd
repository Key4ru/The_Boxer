extends CharacterBody2D

const SPEED = 175.0

# 1. Define the States
enum State { IDLE, BACKWARD_WALK, FORWARD_WALK, PUNCH_LIGHT, PUNCH_HEAVY }
var current_state = State.IDLE

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D2
@onready var sfx_punch: AudioStreamPlayer = $sfx_punch
@onready var damage_emitter: Area2D = $Damage_emmiter

func _ready() -> void:
	# Connect the signal so we know when an attack ends
	sprite.animation_finished.connect(_on_animation_finished)
	# Ensure hitbox is off at start
	damage_emitter.monitoring = false

func _physics_process(delta: float) -> void:
	# 1. Apply Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0

	# 2. Get Input
	var direction := Input.get_axis("ui_left", "ui_right")

	# 3. State & Attack Logic
	if can_attack():
		if Input.is_action_just_pressed("Attack_Light"):
			enter_punch_state(State.PUNCH_LIGHT)
		elif Input.is_action_just_pressed("Attack_Heavy"):
			enter_punch_state(State.PUNCH_HEAVY)
		elif direction > 0:
			current_state = State.FORWARD_WALK
			sprite.flip_h = false # Face Right
		elif direction < 0:
			current_state = State.BACKWARD_WALK
			sprite.flip_h = false  # Face Left (Fixed from your snippet)
		else:
			current_state = State.IDLE

	# 4. Movement Logic
	if not is_punching():
		velocity.x = direction * SPEED
	else:
		# Stop moving or slide slightly during punch
		velocity.x = move_toward(velocity.x, 0, SPEED)

	update_animations()
	move_and_slide()

# Helper to check if we are currently in an attack animation
func is_punching() -> bool:
	return current_state == State.PUNCH_LIGHT or current_state == State.PUNCH_HEAVY

func can_attack() -> bool:
	return not is_punching()

func enter_punch_state(new_state: State) -> void:
	current_state = new_state
	damage_emitter.monitoring = true # Turn on hitbox
	
	if new_state == State.PUNCH_LIGHT:
		sprite.play("punch_light") # Make sure you have this animation name
	elif new_state == State.PUNCH_HEAVY:
		sprite.play("punch_heavy") # Make sure you have this animation name
		
	sfx_punch.play()

func update_animations() -> void:
	# We only trigger travel animations if we aren't punching
	if not is_punching():
		if current_state == State.FORWARD_WALK or current_state == State.BACKWARD_WALK:
			sprite.play("walk")
		else:
			sprite.play("idle")

func _on_animation_finished() -> void:
	# When any punch animation ends, return to IDLE and turn off hitbox
	if sprite.animation == "punch_light" or sprite.animation == "punch_heavy":
		current_state = State.IDLE
		damage_emitter.monitoring = false

# Connect this to your Area2D "area_entered" signal in the editor
func _on_damage_emmiter_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		var damage = 10 if current_state == State.PUNCH_LIGHT else 25
		area.take_damage(damage)
		print("Hit ", area.name, " for ", damage, " damage!")
