extends CharacterBody2D

const SPEED: float = 250.0

func _physics_process(_delta: float) -> void:
	var direction: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	velocity = direction * SPEED

	move_and_slide()
