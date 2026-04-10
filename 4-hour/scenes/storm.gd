extends Polygon2D
class_name StormController

# --- Storm settings ---
@export var end_scale: float = 0.01
@export var reveal_delay: float = 180.0
@export var shrink_duration: float = 60.0
@export var damage_per_second: float = 50.0

# --- State ---
var time: float = 0.0
var active: bool = false

var start_scale: Vector2

# Track who is inside safe zone
var players_inside := {}

func _ready():
	start_scale = scale
	visible = false

	# Connect Area2D signals
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)

	

func _process(delta):
	time += delta
	

	# --- activate storm ---
	if not active and time >= reveal_delay:
		active = true
		visible = true
		
		# IMPORTANT: detect players already inside at start
		await get_tree().process_frame
		for body in $Area2D.get_overlapping_bodies():
			if body.is_in_group("players"):
				players_inside[body] = true

	if not active:
		return

	# --- shrink over time ---
	var t = min((time - reveal_delay) / shrink_duration, 1.0)
	var new_scale = start_scale.lerp(Vector2(end_scale, end_scale), t)
	scale = new_scale

	# --- apply damage outside safe zone ---
	for player in get_tree().get_nodes_in_group("players"):
		

		if not players_inside.has(player):
			if player.has_method("take_damage"):
				player.take_damage(damage_per_second * delta)

# --- Area2D tracking ---
func _on_body_entered(body):
	if body.is_in_group("players"):
		players_inside[body] = true

func _on_body_exited(body):
	if body.is_in_group("players"):
		players_inside.erase(body)
