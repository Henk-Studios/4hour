extends RigidBody2D
class_name BulletBase

@export var speed: float = 2000.0
@export var direction: Vector2 = Vector2.RIGHT
@export var range: float = 80000.0

signal hit_player(player: Player)
signal hit_enemy(enemy: Enemy)

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
		var collider = collision.get_collider()

		# Check if collider is a Player
		if collider is Player:
			hit_player.emit(collider)
		# Check if collider is an Enemy
		elif collider is Enemy:
			hit_enemy.emit(collider)
		# Otherwise it's a wall - destroy the bullet
		else:
			queue_free()

	# Destroy if exceeded range
	if start_position.distance_to(global_position) > range:
		queue_free()
