extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
# NOTE: Make sure your node is named exactly "HitArea" (no spaces) in the scene tree!
@onready var hit_area: Area2D = $HitArea  

var is_hit: bool = false
var hit_cooldown: float = 0.4  # seconds before dummy can be hit again
var hit_timer: float = 0.0

# Fetch default gravity from project settings
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	animated_sprite.play("idle")
	# Connect the Area2D signal to detect the player's punch
	hit_area.area_entered.connect(_on_hit_area_area_entered)

func _physics_process(delta):
	# Apply gravity to the dummy
	if not is_on_floor():
		velocity.y += gravity * delta
	move_and_slide()

func _process(delta):
	# Handle the hit cooldown and return to idle
	if is_hit:
		hit_timer -= delta
		if hit_timer <= 0.0:
			is_hit = false
			animated_sprite.play("idle")

# Triggered when the Player's Attack Area2D overlaps with the Dummy's HitArea Area2D
func _on_hit_area_area_entered(area: Area2D):
	if is_hit:
		return  # Still in cooldown, ignore

	# Get the main Player node (Assuming the Player's Area2D is a direct child of the Player)
	var source = area.get_parent() 

	# Safety check: Ensure the source actually exists before checking variables
	if not is_instance_valid(source):
		return 

	# 1. Check against the "is_attacking" variable in the player script
	if "is_attacking" in source and source.is_attacking:
		trigger_hit()
		
	# 2. Fallback check: look for AnimationPlayer state
	elif source.has_node("AnimationPlayer"):
		var anim_player = source.get_node("AnimationPlayer")
		if anim_player.current_animation in ["punch_light", "punch_heavy"]:
			trigger_hit()

func trigger_hit():
	is_hit = true
	hit_timer = hit_cooldown
	animated_sprite.play("hit")
