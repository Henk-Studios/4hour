extends RigidBody2D

# --- Movement ---
@export var speed: float = 200.0
@export var target_position: Vector2 = Vector2.ZERO

# --- Gunner variables ---
@export var is_gunner: bool = false
@export var shoot_interval: float = 1.0       # Seconds between shots
@export var bullet_speed: float = 400.0
@export var bullet_scene: PackedScene         # Assign your BulletBase scene here

# --- Internal ---
var start_position: Vector2
var shoot_timer: Timer

func _ready():
	sleeping = false
	custom_integrator = true
	start_position = global_position

	# Setup shooting timer if this enemy is a gunner
	if is_gunner and bullet_scene:
		shoot_timer = Timer.new()
		shoot_timer.wait_time = shoot_interval
		shoot_timer.one_shot = false
		shoot_timer.autostart = true
		add_child(shoot_timer)
		shoot_timer.timeout.connect(_on_shoot_timeout)

func _integrate_forces(state):
	# --- Movement ---
	if target_position != Vector2.ZERO:
		var desired_dir = (target_position - global_position).normalized()
		var motion = desired_dir * speed * state.get_step()
		var collision = move_and_collide(motion)
		if collision:
			# Slide along wall
			var slide_dir = desired_dir.slide(collision.get_normal())
			slide_dir = slide_dir.normalized() * speed * 1.5 * state.get_step()
			move_and_collide(slide_dir)

	

func _on_shoot_timeout():
	if not bullet_scene or target_position == Vector2.ZERO:
		return
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	# Aim bullet toward the target point
	bullet.direction = (target_position - global_position).normalized()
	bullet.speed = bullet_speed
	get_tree().current_scene.add_child(bullet)
