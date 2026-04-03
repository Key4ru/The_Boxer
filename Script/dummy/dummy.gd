extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var hit_count: int = 0

func _ready() -> void:
	anim.play("idle")
	anim.animation_finished.connect(_on_animation_finished)

func receive_hit(hit_type: String) -> void:
	hit_count += 1
	print("Dummy hit! Total: %d | Type: %s" % [hit_count, hit_type])
	anim.play("dummy")

func _on_animation_finished() -> void:
	if anim.animation == "dummy":
		anim.play("idle")
