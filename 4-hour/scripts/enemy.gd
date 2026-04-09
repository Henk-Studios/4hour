extends RigidBody2D

@export var speed: float = 200.0
@export var target_position: Vector2 = Vector2.ZERO
 

func _ready():
	sleeping = false
	custom_integrator = true  

func _integrate_forces(state):
	if target_position == Vector2.ZERO:
		return
	
	var desired_dir = (target_position - global_position).normalized()
	var motion = desired_dir * speed * state.get_step()
	
	var collision = move_and_collide(motion)
	if collision:
		# Slide along wall
		var slide_dir = desired_dir.slide(collision.get_normal())
		# Keep speed consistent
		slide_dir = slide_dir.normalized() * speed * 1.5 * state.get_step()
		move_and_collide(slide_dir)
