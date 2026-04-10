extends Node2D
class_name EnemySpawner

@export var enemy_scene: PackedScene

# --- Spawn tuning ---
@export var start_spawn_interval: float = 14.0
@export var end_spawn_interval: float = 5
@export var ramp_duration: float = 180.0  # 3 minutes

@export var start_spawn_count: int = 2
@export var initial_spawn_delay: float = 1.0

@export var max_enemies: int = 10000
@export var spawn_offset: Vector2 = Vector2.ZERO

var current_enemies: int = 0
var spawn_timer: Timer

var elapsed_time: float = 0.0
var current_interval: float

func _ready():
	current_interval = start_spawn_interval

	# Delay initial spawn by 1 second
	var start_timer = Timer.new()
	start_timer.one_shot = true
	start_timer.wait_time = initial_spawn_delay
	add_child(start_timer)
	start_timer.timeout.connect(_spawn_initial_batch)
	start_timer.start()

	# Setup repeating spawn timer (starts normally)
	spawn_timer = Timer.new()
	spawn_timer.wait_time = current_interval
	spawn_timer.one_shot = false
	spawn_timer.autostart = true
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_on_spawn_timeout)

func _spawn_initial_batch():
	for i in range(start_spawn_count):
		_spawn_enemy()

func _process(delta):
	elapsed_time = min(elapsed_time + delta, ramp_duration)

	var t = elapsed_time / ramp_duration
	current_interval = lerp(start_spawn_interval, end_spawn_interval, t)

	if spawn_timer:
		spawn_timer.wait_time = current_interval

func _on_spawn_timeout():
	_spawn_enemy()

func _spawn_enemy():
	if not enemy_scene:
		return
	if max_enemies > 0 and current_enemies >= max_enemies:
		return

	var enemy = enemy_scene.instantiate()
	enemy.global_position = global_position + spawn_offset
	get_tree().current_scene.add_child(enemy)
	current_enemies += 1

	if enemy.has_signal("tree_exited"):
		enemy.tree_exited.connect(_on_enemy_removed)

func _on_enemy_removed():
	current_enemies = max(0, current_enemies - 1)
