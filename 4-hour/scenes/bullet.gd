extends RigidBody2D
class_name BulletBase  # makes it a base class you can extend

@export var speed: float = 400.0         # movement speed
@export var range: float = 800.0         # max distance before destroying
@export var damage: int = 10             # damage applied
@export var explode_on_impact: bool = false
@export var explosion_radius: float = 100.0
@export var explosion_force: float = 500.0
@export var explosion_scene: PackedScene  # optional visual effect

var start_position: Vector2

func _ready():
	custom_integrator = true
	start_position = global_position
	sleeping = false

func _integrate_forces(state):
	# Move forward
	var motion = transform.x * speed * state.get_step()
	var collision = move_and_collide(motion)
	
	if collision:
		_on_hit(collision)
	
	# Destroy after exceeding range
	if start_position.distance_to(global_position) >= range:
		queue_free()

# Called on collision
func _on_hit(collision: KinematicCollision2D) -> void:
	if explode_on_impact:
		_explode()
	
	# Apply damage if target has apply_damage()
	if collision.collider.has_method("apply_damage"):
		collision.collider.apply_damage(damage)
	
	queue_free()

# Explosion logic
func _explode() -> void:
	# Visual effect
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		explosion.global_position = global_position
		get_tree().current_scene.add_child(explosion)
	
	# Apply force to physics bodies in area
	var space = get_world_2d().direct_space_state
	var result = space.intersect_circle(global_position, explosion_radius, [], collision_mask)
	
	for item in result:
		if item.collider is RigidBody2D:
			var body = item.collider
			var dir = (body.global_position - global_position).normalized()
			body.apply_impulse(Vector2.ZERO, dir * explosion_force)
