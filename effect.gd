extends Node2D

func _ready():
	# DEBUG: Check if we spawned correctly
	print("DEBUG: Hit Effect spawned at: ", global_position)

# Start the animation on the child node
	if has_node("Effect"):
		$Effect.play("effect")
		# Connect the signal from the child 'Effect' to this script's 'queue_free'
		$Effect.animation_finished.connect(_on_animation_finished)
	else:
		print("DEBUG ERROR: Child node named 'Effect' not found!")

func _on_animation_finished() -> void:
	print("DEBUG: Effect finished, removing from scene.")
	queue_free()
