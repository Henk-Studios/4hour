extends CharacterBody2D
class_name Player

@export var player_index: int = 0
@export var speed: float = 800.0
@export var max_hp: float = 1000.0
@export var hp: float = 1000.0

# Shooting stats
@export var bullet_speed: float = 2000.0
@export var shoot_interval: float = 0.2
var shoot_cooldown: float = 0.0

@export var polygon: Polygon2D
@export var collision_shape: CollisionShape2D
@export var bullet_scene: PackedScene

var input_type: String = "keyboard"
var device_id: int = -1
var camera: Camera2D

var left_action: String
var right_action: String
var up_action: String
var down_action: String

var aim_left_action: String
var aim_right_action: String
var aim_up_action: String
var aim_down_action: String
var shoot_action: String

var hp_bar: ProgressBar
var wrapper: Node2D

const COLORS = [Color.CRIMSON, Color.DODGER_BLUE, Color.LIME_GREEN, Color.GOLD]

func _ready() -> void:
	hp = max_hp
	hp_bar = ProgressBar.new()
	hp_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hp_bar.custom_minimum_size = Vector2(100, 20)
	hp_bar.position = Vector2(-50, -120)
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	hp_bar.show_percentage = false
	hp_bar.modulate = Color(0, 1, 0)
	wrapper = Node2D.new()
	wrapper.top_level = true
	wrapper.add_child(hp_bar)
	add_child(wrapper)

	if polygon:
		polygon.color = COLORS[player_index % COLORS.size()]
		
	_setup_controls()

func _setup_controls() -> void:
	left_action = "move_left_%d" % player_index
	right_action = "move_right_%d" % player_index
	up_action = "move_up_%d" % player_index
	down_action = "move_down_%d" % player_index
	
	aim_left_action = "aim_left_%d" % player_index
	aim_right_action = "aim_right_%d" % player_index
	aim_up_action = "aim_up_%d" % player_index
	aim_down_action = "aim_down_%d" % player_index
	shoot_action = "shoot_%d" % player_index
	
	# Add actions if they don't exist yet
	var actions = [left_action, right_action, up_action, down_action, aim_left_action, aim_right_action, aim_up_action, aim_down_action, shoot_action]
	for action in actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			# Add a small deadzone for controllers
			InputMap.action_set_deadzone(action, 0.2)
			
	if input_type == "keyboard":
		_add_key_event(left_action, KEY_A)
		_add_key_event(right_action, KEY_D)
		_add_key_event(up_action, KEY_W)
		_add_key_event(down_action, KEY_S)
		_add_key_event(shoot_action, KEY_SPACE)
		
		# also add left click just in case
		var mb_event = InputEventMouseButton.new()
		mb_event.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event(shoot_action, mb_event)
	else:
		_add_joypad_axis_event(left_action, device_id, JOY_AXIS_LEFT_X, -1.0)
		_add_joypad_axis_event(right_action, device_id, JOY_AXIS_LEFT_X, 1.0)
		_add_joypad_axis_event(up_action, device_id, JOY_AXIS_LEFT_Y, -1.0)
		_add_joypad_axis_event(down_action, device_id, JOY_AXIS_LEFT_Y, 1.0)
		
		# Aim with right stick
		_add_joypad_axis_event(aim_left_action, device_id, JOY_AXIS_RIGHT_X, -1.0)
		_add_joypad_axis_event(aim_right_action, device_id, JOY_AXIS_RIGHT_X, 1.0)
		_add_joypad_axis_event(aim_up_action, device_id, JOY_AXIS_RIGHT_Y, -1.0)
		_add_joypad_axis_event(aim_down_action, device_id, JOY_AXIS_RIGHT_Y, 1.0)
		
		# Shoot with right trigger or right bumper
		_add_joypad_axis_event(shoot_action, device_id, JOY_AXIS_TRIGGER_RIGHT, 1.0)
		_add_joypad_button_event(shoot_action, device_id, JOY_BUTTON_RIGHT_SHOULDER)

func _add_key_event(action: String, keycode: Key) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)

func _add_joypad_axis_event(action: String, device: int, axis: JoyAxis, direction: float) -> void:
	var event = InputEventJoypadMotion.new()
	event.device = device
	event.axis = axis
	event.axis_value = direction
	InputMap.action_add_event(action, event)

func _add_joypad_button_event(action: String, device: int, button: JoyButton) -> void:
	var event = InputEventJoypadButton.new()
	event.device = device
	event.button_index = button
	InputMap.action_add_event(action, event)

func take_damage(amount: float) -> void:
	hp -= amount
	if hp_bar:
		hp_bar.value = hp
	if hp <= 0:
		queue_free()

func _physics_process(_delta: float) -> void:
	if is_instance_valid(wrapper):
		wrapper.global_position = global_position
		wrapper.global_rotation = 0
		
	# Movement
	var input_vector = Input.get_vector(left_action, right_action, up_action, down_action)
	velocity = input_vector * speed
	
	velocity = input_vector * speed
	move_and_slide()
	
	# Aiming
	if input_type == "keyboard":
		# Keyboard player looks at the mouse
		if camera:
			# Convert screen mouse position to world coordinates using the camera
			var viewport = camera.get_viewport()
			var mouse_screen_pos = viewport.get_mouse_position()
			var world_pos = camera.get_global_position()
			# Account for camera zoom and viewport size
			var viewport_size = viewport.get_visible_rect().size
			world_pos += (mouse_screen_pos - viewport_size / 2.0) / camera.zoom
			look_at(world_pos)
	else:
		# Controller players look using the right stick
		var aim_vector = Input.get_vector(aim_left_action, aim_right_action, aim_up_action, aim_down_action)
		if aim_vector.length_squared() > 0.1:
			rotation = aim_vector.angle()
	
	# Shooting
	if shoot_cooldown > 0.0:
		shoot_cooldown -= _delta
		
	if Input.is_action_pressed(shoot_action) and shoot_cooldown <= 0.0:
		_shoot()
		shoot_cooldown = shoot_interval

func _shoot() -> void:
	var bullet = bullet_scene.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = global_position + Vector2.RIGHT.rotated(rotation) * 100 # Spawn a bit in front of the player
	bullet.direction = Vector2.RIGHT.rotated(rotation)
	bullet.speed = bullet_speed
	bullet.global_rotation = rotation

func pickup_upgrade(type: String) -> void:
	match type:
		"health":
			hp = min(hp + max_hp * 0.2, max_hp)
			if hp_bar:
				hp_bar.value = hp
		"bullet_speed":
			bullet_speed += 200.0
		"bullet_rate":
			shoot_interval = max(0.05, shoot_interval - 0.02)
