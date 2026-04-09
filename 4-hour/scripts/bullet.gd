extends RigidBody2D
class_name BulletBase

@export var speed: float = 1200.0
@export var direction: Vector2 = Vector2.RIGHT
@export var range: float = 80000.0

var start_position: Vector2

func _ready():
	start_position = global_position
	sleeping = false
	custom_integrator = true
	direction = direction.normalized()

func _integrate_forces(state):
	# Move bullet
	var motion = direction * speed * state.get_step()
	var collision = move_and_collide(motion)
	if collision:
		queue_free()  # Destroy on impact

	# Destroy if exceeded range
	if start_position.distance_to(global_position) > range:
		queue_free()
