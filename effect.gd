extends Node2D

func _ready():
	if has_node("Effect"):
		$Effect.play("effect")
		$Effect.animation_finished.connect(_on_animation_finished)

func _on_animation_finished() -> void:
	queue_free()
