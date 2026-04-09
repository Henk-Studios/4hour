extends RigidBody2D

# --- Movement ---
@export var speed: float = 200.0
@export var bounce_force: float = 200.0

var target_player: Node2D = null
var target_position: Vector2 = Vector2.ZERO

# --- Gunner variables ---
@export var is_gunner: bool = false
@export var shoot_interval: float = 1.0       # Seconds between shots
@export var bullet_speed: float = 400.0
@export var bullet_scene: PackedScene         # Assign your BulletBase scene here

# --- Unstuck variables ---
@export var stuck_threshold: float = 0.05   # Minimum movement to consider “moving”
@export var stuck_check_time: float = 0.3  # Seconds to check for stuck
@export var unstuck_force: float = 300.0
@export var unstuck_duration: float = 0.2  # How long to move in random direction

var shoot_timer: Timer
var last_position: Vector2
var stuck_timer: float = 0.0
var unstuck_timer: float = 0.0
var unstuck_dir: Vector2 = Vector2.ZERO


func _ready():
	sleeping = false
	custom_integrator = true

	# Choose a target player at spawn
	var players = get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		target_player = players[randi() % players.size()]
		target_position = target_player.global_position

	# Setup shooting timer if this enemy is a gunner
	if is_gunner and bullet_scene:
		shoot_timer = Timer.new()
		shoot_timer.wait_time = shoot_interval
		shoot_timer.one_shot = false
		shoot_timer.autostart = true
		add_child(shoot_timer)
		shoot_timer.timeout.connect(_on_shoot_timeout)

func _integrate_forces(state):
	# Update target position if the player still exists
	if target_player and target_player.is_inside_tree():
		target_position = target_player.global_position

	if target_position == Vector2.ZERO:
		return

	# --- Movement direction ---
	var desired_dir = (target_position - global_position).normalized()
	var motion = desired_dir * speed * state.get_step()

	# --- Move the enemy ---
	var collision = move_and_collide(motion)
	if collision:
		var slide_dir = desired_dir.slide(collision.get_normal())
		slide_dir = slide_dir.normalized() * speed * 1.5 * state.get_step()
		move_and_collide(slide_dir)

	# --- Unstuck detection ---
	var moved = global_position.distance_to(last_position)
	if moved < stuck_threshold and unstuck_timer <= 0.0:
		stuck_timer += state.get_step()
		if stuck_timer >= stuck_check_time:
			# Pick a random direction to move for a short burst
			var angle = randf() * PI * 2
			unstuck_dir = Vector2(cos(angle), sin(angle)).normalized()
			unstuck_timer = unstuck_duration
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0


	last_position = global_position


func _on_shoot_timeout():
	if not bullet_scene or target_position == Vector2.ZERO:
		return
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	# Aim bullet toward the target point
	bullet.direction = (target_position - global_position).normalized()
	bullet.speed = bullet_speed
	get_tree().current_scene.add_child(bullet)
