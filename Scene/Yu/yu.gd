extends CharacterBody2D

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var hit_effect_scene: PackedScene

const SPEED = 175.0
const LIGHT_PUNCH_DAMAGE = 2
const HEAVY_PUNCH_DAMAGE = 4
const HEALTH_MAX = 50

var is_attacking: bool = false
var health: int = HEALTH_MAX

func _ready():
	add_to_group("player")
	anim_player.animation_finished.connect(_on_animation_finished)
	anim_player.play("idle")

func _physics_process(_delta):
	if is_attacking:
		velocity.x = 0
	else:
		handle_movement()
		handle_attack_input()
	move_and_slide()

func handle_movement():
	var direction = Input.get_axis("backward", "forward")
	if direction != 0:
		var anim_to_play = "forward" if direction > 0 else "backward"
		if animated_sprite.animation != anim_to_play:
			animated_sprite.play(anim_to_play)
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if is_on_floor():
			animated_sprite.play("idle")

func handle_attack_input():
	if Input.is_action_just_pressed("Attack_Light"):
		start_attack("punch_light")
	elif Input.is_action_just_pressed("Attack_Heavy"):
		start_attack("punch_heavy")

func start_attack(attack_name: String):
	if not anim_player.has_animation(attack_name):
		print("DEBUG ERROR: AnimationPlayer missing: ", attack_name)
		return
	print("DEBUG: Player starting: ", attack_name)
	is_attacking = true
	velocity.x = 0
	anim_player.play(attack_name)

func _on_animation_finished(anim_name: String):
	if anim_name in ["punch_light", "punch_heavy"]:
		print("DEBUG: " + anim_name + " finished. Movement restored.")
		is_attacking = false
		animated_sprite.play("idle")

# --- HIT DETECTION LOGIC ---
func _on_light_punch_body_entered(body):
	_handle_hit(body, $"Light Punch/CollisionShape2D".global_position, LIGHT_PUNCH_DAMAGE)

func _on_heavy_punch_body_entered(body):
	_handle_hit(body, $"Heavy Punch/CollisionShape2D".global_position, HEAVY_PUNCH_DAMAGE)

func _handle_hit(body, hit_pos: Vector2, damage: int):
	print("DEBUG: Collision detected with: ", body.name)
	
	if body.is_in_group("enemy"):
		print("DEBUG: Successful HIT on Enemy!")
		spawn_hit_effect(hit_pos)
		if body.has_method("take_damage"):
			body.take_damage(damage)
	else:
		print("DEBUG: Hit something not in 'enemy' group.")

func spawn_hit_effect(hit_pos: Vector2):
	if hit_effect_scene:
		var effect = hit_effect_scene.instantiate()
		get_tree().current_scene.add_child(effect)
		effect.global_position = hit_pos
		if effect is AnimatedSprite2D:
			effect.play("default")
		print("DEBUG: Hit effect spawned at: ", hit_pos)
	else:
		print("DEBUG ERROR: No hit_effect_scene assigned in Inspector!")

# --- DAMAGE & DEATH ---
func take_damage(amount: int):
	health -= amount
	print("DEBUG: Player took ", amount, " damage. HP: ", health, "/", HEALTH_MAX)
	if health <= 0:
		die()

func die():
	print("DEBUG: Player defeated!")
	queue_free()
