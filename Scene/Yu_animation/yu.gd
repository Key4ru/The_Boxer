class_name yu
extends "res://Script/Yu/yu.gd"

func update_animations() -> void:
	match current_state:
		State.IDLE:
			sprite.play("stance_idle")
		State.FORWARD_WALK:
			sprite.play("forward_walk")
		State.BACKWARD_WALK:
			sprite.play("backward_walk")
