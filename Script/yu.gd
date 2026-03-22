extends CharacterBody2D

# Movement Constants
const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var isAttacking = false

# Node References
@onready var animated_sprite_2d_2: AnimatedSprite2D = $AnimatedSprite2D2

func _ready() -> void:
	# Connect the signal so we know when the animation finishes
	animated_sprite_2d_2.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	# 1. Apply Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 2. Handle Attack Input (using Space/UI Select as example)
	if Input.is_action_just_pressed("Attack") and not isAttacking:
		punch()

	# 3. Handle Jump Input
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not isAttacking:
		velocity.y = JUMP_VELOCITY

	# 4. Get Input Direction
	var direction := Input.get_axis("ui_left", "ui_right")
	
	# 5. Handle Movement (We disable movement while punching for a "heavy" feel, 
	# or keep it if you want "run-and-punch")
	if direction and not isAttacking:
		velocity.x = direction * SPEED
		animated_sprite_2d_2.flip_h = (direction < 0)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# 6. Handle Animations
	update_animations(direction)

	move_and_slide()

func punch() -> void:
	isAttacking = true
	animated_sprite_2d_2.play("punching")

func update_animations(direction: float) -> void:
	# If we are attacking, don't let the other logic play idle/walk
	if isAttacking:
		return 

	if not is_on_floor():
		animated_sprite_2d_2.play("idle") # Usually a 'jump' anim here
	elif direction != 0:
		animated_sprite_2d_2.play("walking")
	else:
		animated_sprite_2d_2.play("idle")

# This function runs automatically when ANY animation ends
func _on_animation_finished() -> void:
	if animated_sprite_2d_2.animation == "punching":
		isAttacking = false
