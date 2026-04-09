extends CharacterBody2D
class_name Player

@export var player_index: int = 0
@export var speed: float = 800.0
@export var polygon: Polygon2D
@export var collision_shape: CollisionShape2D

var input_type: String = "keyboard"
var device_id: int = -1

var left_action: String
var right_action: String
var up_action: String
var down_action: String

var aim_left_action: String
var aim_right_action: String
var aim_up_action: String
var aim_down_action: String

const COLORS = [Color.CRIMSON, Color.DODGER_BLUE, Color.LIME_GREEN, Color.GOLD]

func _ready() -> void:
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
    
    # Add actions if they don't exist yet
    var actions = [left_action, right_action, up_action, down_action, aim_left_action, aim_right_action, aim_up_action, aim_down_action]
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

func _physics_process(_delta: float) -> void:
    # Movement
    var input_vector = Input.get_vector(left_action, right_action, up_action, down_action)
    velocity = input_vector * speed
    
    velocity = input_vector * speed
    move_and_slide()
    if input_type == "keyboard":
        # Keyboard player looks at the mouse
        look_at(get_global_mouse_position())
    else:
        # Controller players look using the right stick
        var aim_vector = Input.get_vector(aim_left_action, aim_right_action, aim_up_action, aim_down_action)
        if aim_vector.length_squared() > 0.1:
            rotation = aim_vector.angle()
