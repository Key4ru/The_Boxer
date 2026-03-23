extends CharacterBody2D

# Movement Constants
const SPEED = 175.0

var isAttacking = false

# Node References
@onready var animated_sprite_2d_2: AnimatedSprite2D = $AnimatedSprite2D2
@onready var sfx_punch: AudioStreamPlayer = $sfx_punch

func _ready() -> void:
	animated_sprite_2d_2.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	# Apply Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Attack
	if Input.is_action_just_pressed("Attack") and not isAttacking:
		punch()



	# Movement
	var direction := Input.get_axis("ui_left", "ui_right")

	if direction != 0 and not isAttacking:
		velocity.x = direction * SPEED
		animated_sprite_2d_2.flip_h = (direction < 0)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Animations
	update_animations(direction)

	move_and_slide()

# ✅ Keep ONLY this one
func punch() -> void:
	isAttacking = true
	animated_sprite_2d_2.play("punch") # make sure this exists
	sfx_punch.play()

func update_animations(direction: float) -> void:
	if isAttacking:
		return 

	if not is_on_floor():
		animated_sprite_2d_2.play("stance_idle") # or "jump"
	elif direction > 0:
		animated_sprite_2d_2.play("forward_walk")
	elif direction < 0:
		animated_sprite_2d_2.play("backward_walk")
		animated_sprite_2d_2.flip_h = false
	else:
		animated_sprite_2d_2.play("stance_idle")

func _on_animation_finished() -> void:
	if animated_sprite_2d_2.animation == "punch":
		isAttacking = false
