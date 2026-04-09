extends Control
class_name Menu

@export var play_button: Button
@export var player_buttons_container: HBoxContainer
@export var controllers_label: Label
@export var time_slider: HSlider
@export var time_label: Label

var player_inputs: Array[int] = [-1, -1, -1, -1]
# input mappings: -1 = none, 0 = keyboard, 1 = controller 0, 2 = controller 1, 3 = controller 2, 4 = controller 3
var max_devices: int = 5
var player_buttons: Array[Button] = []

func _ready() -> void:
	play_button.pressed.connect(_on_play_button_pressed)
	time_slider.value_changed.connect(_on_time_slider_value_changed)
	_on_time_slider_value_changed(time_slider.value)
	
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_update_controller_count()
	
	if player_buttons_container:
		for i in range(4):
			var btn: Button = player_buttons_container.get_child(i) as Button
			player_buttons.append(btn)
			btn.pressed.connect(_on_player_button_pressed.bind(i))
			
	# Initialize first player with Keyboard (0)
	player_inputs[0] = 0
	_update_button_texts()

func _on_player_button_pressed(player_idx: int) -> void:
	var current_input = player_inputs[player_idx]
	var next_input = current_input
	
	# Cycle until we find an available input
	while true:
		next_input += 1
		
		# Wrap around back to None (-1) after checking all devices
		if next_input >= max_devices:
			next_input = -1
			break
			
		# If the input isn't used by another player, we can use it
		var is_used = false
		for i in range(player_inputs.size()):
			if i != player_idx and player_inputs[i] == next_input:
				is_used = true
				break
				
		if not is_used:
			break
			
	player_inputs[player_idx] = next_input
	_update_button_texts()

func _update_button_texts() -> void:
	var connected_pads = Input.get_connected_joypads()
	
	for i in range(4):
		var btn = player_buttons[i]
		var input_val = player_inputs[i]
		
		btn.remove_theme_color_override("font_color")
		
		if input_val == -1:
			btn.text = "Click to add player"
		elif input_val == 0:
			btn.text = "Player %d: Keyboard" % (i + 1)
		else:
			var device_id = input_val - 1
			btn.text = "Player %d: Controller %d" % [(i + 1), device_id]
			if not connected_pads.has(device_id):
				btn.add_theme_color_override("font_color", Color.RED)

func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	_update_controller_count()
	_update_button_texts()

func _update_controller_count() -> void:
	if controllers_label:
		var count = Input.get_connected_joypads().size()
		controllers_label.text = "Connected controllers: %d" % count

func _on_play_button_pressed() -> void:
	var active_players = []
	for i in range(4):
		if player_inputs[i] != -1:
			active_players.append({
				"player_index": i,
				"input_type": "keyboard" if player_inputs[i] == 0 else "controller",
				"device_id": player_inputs[i] - 1 # -1 for keyboard, 0-3 for controllers
			})
			
	Manager.scene.change_scene("res://scenes/map.tscn", {
		"players": active_players,
		"match_time": time_slider.value
	})

func _on_time_slider_value_changed(value: float) -> void:
	var minutes = int(value) / 60
	var seconds = int(value) % 60
	time_label.text = "PvP Time: %d:%02d" % [minutes, seconds]
