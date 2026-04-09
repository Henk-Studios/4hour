extends RigidBody2D
class_name Enemy

# --- Health ---
@export var max_hp: float = 100.0
var hp: float = 100.0
var hp_bar: ProgressBar

# --- Targeting ---
var target_player: Node2D = null
var target_position: Vector2 = Vector2.ZERO

# --- Movement (burst system) ---
@export var burst_force: float = 600.0
@export var burst_interval: float = 0.8
@export var max_speed: float = 350.0

var burst_timer: float = 0.0

# --- Gunner variables ---
@export var is_gunner: bool = true
@export var shoot_interval: float = 1.0
@export var bullet_speed: float = 1333.0
@export var bullet_scene: PackedScene

# --- Upgrades ---
@export var upgrade_drop_chance: float = 0.3
var upgrade_scene = preload("res://scenes/upgrade.tscn")

var shoot_timer: Timer

var wrapper: Node2D

func _ready():
	hp = max_hp
	hp_bar = ProgressBar.new()
	hp_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hp_bar.custom_minimum_size = Vector2(100, 20)
	hp_bar.position = Vector2(-50, -80)
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	hp_bar.show_percentage = false
	hp_bar.modulate = Color(1, 0, 0)
	# Wrap in Node2D to prevent rotation issues with rigidbody
	wrapper = Node2D.new()
	wrapper.top_level = true
	wrapper.add_child(hp_bar)
	add_child(wrapper)

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

func take_damage(amount: float) -> void:
	hp -= amount
	if hp_bar:
		hp_bar.value = hp
	if hp <= 0:
		_die()

func _die():
	if randf() <= upgrade_drop_chance and upgrade_scene:
		var upgrade = upgrade_scene.instantiate()
		upgrade.global_position = global_position
		get_tree().current_scene.call_deferred("add_child", upgrade)
	queue_free()

func _physics_process(delta: float):
	if is_instance_valid(wrapper):
		wrapper.global_position = global_position
		wrapper.global_rotation = 0

func _integrate_forces(state):
	if not target_player or not target_player.is_inside_tree():
		return
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
	if target_position == Vector2.ZERO:
		return

	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.direction = (target_position - global_position).normalized()
	bullet.speed = bullet_speed
	get_tree().current_scene.add_child(bullet)
