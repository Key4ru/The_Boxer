class_name BasicTakeda
extends "res://Script/Takeda/takeda.gd"

@export var player : yu
@onready var reaction_timer: Timer = $ReactionTimer

var aggression_level: float = 0.9 # High aggression so he stays on you

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if player != null:
		var direction_to_player = sign(player.global_position.x - global_position.x)
		var dist = abs(player.global_position.x - global_position.x)
		
		# 🛑 If already punching, don't change states
		if current_state == State.PUNCH:
			velocity.x = move_toward(velocity.x, 0, SPEED * delta)
			return 

		# 🧠 Thinking delay (makes him stand still for a split second)
		if not reaction_timer.is_stopped():
			velocity.x = 0
			current_state = State.IDLE
			return

		# --- SMART POSITIONING ---
		
		if dist > 35.0: 
			# ✅ CLOSER: He won't stop until he's 35 pixels away (almost touching)
			velocity.x = direction_to_player * SPEED
			current_state = State.FORWARD_WALK
			
		elif dist < 15.0:
			# ✅ RETREAT: Only backs up if you are literally inside him
			velocity.x = -direction_to_player * (SPEED * 0.5)
			current_state = State.BACKWARD_WALK
			
		else:
			# ✅ COMBAT ZONE: Between 15px and 35px
			velocity.x = 0
			make_combat_decision()

	move_and_slide()
	update_animations()

func make_combat_decision() -> void:
	var decision = randf()
	
	if decision < aggression_level:
		enter_punch_state()
	else:
		# Smart move: He waits for you to move first
		current_state = State.IDLE
		reaction_timer.start(0.3) 

func enter_punch_state() -> void:
	current_state = State.PUNCH
	sprite.play("punch")

func _on_animation_finished() -> void:
	if sprite.animation == "punch":
		current_state = State.IDLE
		# Random recovery time so he isn't a robot
		reaction_timer.start(randf_range(0.2, 0.5))
