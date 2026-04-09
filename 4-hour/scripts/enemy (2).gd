extends RigidBody2D

# --- Targeting ---
var target_player: Node2D = null
var target_position: Vector2 = Vector2.ZERO

# --- Movement (burst system) ---
@export var burst_force: float = 600.0
@export var burst_interval: float = 0.8
@export var max_speed: float = 350.0

var burst_timer: float = 0.0

# --- Gunner variables ---
@export var is_gunner: bool = false
@export var shoot_interval: float = 1.0
@export var bullet_speed: float = 400.0
@export var bullet_scene: PackedScene

var shoot_timer: Timer

func _ready():
	sleeping = false
	custom_integrator = true

	# Pick ONE player at spawn
	var players = get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		target_player = players[randi() % players.size()]

	# Shooting setup
	if is_gunner and bullet_scene:
		shoot_timer = Timer.new()
		shoot_timer.wait_time = shoot_interval
		shoot_timer.one_shot = false
		shoot_timer.autostart = true
		add_child(shoot_timer)
		shoot_timer.timeout.connect(_on_shoot_timeout)

func _integrate_forces(state):
	if target_player and target_player.is_inside_tree():
		target_position = target_player.global_position

	# --- BURST MOVEMENT ---
	burst_timer -= state.get_step()

	if burst_timer <= 0.0:
		_apply_burst()
		burst_timer = burst_interval

	# --- Clamp speed so physics stays stable ---
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed

func _apply_burst():
	if target_position == Vector2.ZERO:
		return

	var dir = (target_position - global_position).normalized()

	# small randomness so they don’t stack perfectly
	dir = (dir + Vector2(randf_range(-0.2, 0.2), randf_range(-0.2, 0.2))).normalized()

	apply_central_impulse(dir * burst_force)

func _on_shoot_timeout():
	if not bullet_scene or target_position == Vector2.ZERO:
		return

	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.direction = (target_position - global_position).normalized()
	bullet.speed = bullet_speed
	get_tree().current_scene.add_child(bullet)
