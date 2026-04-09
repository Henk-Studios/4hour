extends Polygon2D
class_name StormController

# --- Storm settings ---
@export var start_radius: float = 2000.0
@export var end_radius: float = 200.0

@export var reveal_delay: float = 1.0
@export var shrink_duration: float = 180.0

# --- State ---
var time: float = 0.0
var active: bool = false
var current_radius: float

func _ready():
	current_radius = start_radius
	visible = false

	# IMPORTANT: make sure scaling happens from center
	

func _process(delta):
	time += delta

	# --- activate storm ---
	if not active and time >= reveal_delay:
		active = true
		visible = true

	if not active:
		return

	# --- shrink over time ---
	var t = min((time - reveal_delay) / shrink_duration, 1.0)
	current_radius = lerp(start_radius, end_radius, t)

	_apply_storm_scale()

func _apply_storm_scale():
	# base polygon is assumed to be radius = 1 unit circle or designed shape
	var scale_factor = current_radius / start_radius
	scale = Vector2(scale_factor, scale_factor)
