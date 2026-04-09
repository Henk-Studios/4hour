extends Node2D
class_name EnemySpawner

@export var enemy_scene: PackedScene       # The enemy to spawn
@export var spawn_interval: float = 3.0    # Seconds between spawns
@export var max_enemies: int = 10000      # Optional max on screen
@export var spawn_offset: Vector2 = Vector2.ZERO  # Offset from spawner position

var current_enemies: int = 0
var spawn_timer: Timer

func _ready():
	# Setup spawn timer
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false
	spawn_timer.autostart = true
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_on_spawn_timeout)

func _on_spawn_timeout():
	if not enemy_scene:
		return
	if max_enemies > 0 and current_enemies >= max_enemies:
		return

	# Instance and add enemy
	var enemy = enemy_scene.instantiate()
	enemy.global_position = global_position + spawn_offset
	get_tree().current_scene.add_child(enemy)
	current_enemies += 1

	# Optional: connect to enemy death to decrease current_enemies
	if enemy.has_signal("tree_exited"):
		enemy.tree_exited.connect(_on_enemy_removed)

func _on_enemy_removed():
	current_enemies = max(0, current_enemies - 1)
