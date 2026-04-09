extends RigidBody2D

@export var speed: float = 200.0
@export var target_position: Vector2 = Vector2.ZERO

func _physics_process(delta):
	if target_position == Vector2.ZERO:
		return
	
	var direction = (target_position - global_position).normalized()
	
	linear_velocity = direction * speed
