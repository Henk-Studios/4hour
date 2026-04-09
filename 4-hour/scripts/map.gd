extends Node2D
class_name Map

const PLAYER_SCENE = preload("res://scenes/player.tscn")
@export var grid: GridContainer

var camera_targets: Array[Dictionary] = []

func setup(params: Dictionary) -> void:
	print("Map scene setup with params: ", params)
	
	if params.has("players"):
		var num_players = params["players"].size()
		
		# Add black background behind the viewports to hide the main viewport
		var bg := ColorRect.new()
		bg.color = Color.BLACK
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		$UI.add_child(bg)
		$UI.move_child(bg, 0)
		
		grid.set_anchors_preset(Control.PRESET_FULL_RECT)
		if num_players <= 2:
			grid.columns = num_players
		else:
			grid.columns = 2
		
		var spawn_positions = [Vector2(-200, -200), Vector2(200, -200), Vector2(-200, 200), Vector2(200, 200)]
		var screen_center = get_viewport_rect().size / 2.0
		
		for i in range(num_players):
			var player_data = params["players"][i]
			var player = PLAYER_SCENE.instantiate() as Player
			
			player.player_index = player_data["player_index"]
			player.input_type = player_data["input_type"]
			player.device_id = player_data["device_id"]
			
			# Position them relative to the center
			player.position = screen_center + spawn_positions[i % spawn_positions.size()]
			add_child(player)
			
			var container := SubViewportContainer.new()
			container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			container.size_flags_vertical = Control.SIZE_EXPAND_FILL
			container.stretch = true
			container.mouse_filter = Control.MOUSE_FILTER_IGNORE
			grid.add_child(container)
			
			var vp := SubViewport.new()
			vp.world_2d = get_viewport().world_2d
			vp.transparent_bg = true
			container.add_child(vp)
			
			var cam := Camera2D.new()
			cam.position = player.position
			vp.add_child(cam)
			
			player.camera = cam
			camera_targets.append({"camera": cam, "target": player})
			
	Manager.scene.finish_loading()

func _process(delta: float) -> void:
	for item in camera_targets:
		if is_instance_valid(item.target) and is_instance_valid(item.camera):
			var prev_position = item.camera.position
			item.camera.position = item.camera.position.lerp(item.target.position, 5.0 * delta)
			
			# Calculate camera movement speed and adjust zoom
			var movement_speed = prev_position.distance_to(item.camera.position) / delta if delta > 0 else 0.0
			var zoom_factor = inverse_lerp(0.0, 1000, movement_speed)
			var target_zoom = lerp(1.0, 0.5, zoom_factor)
			item.camera.zoom = item.camera.zoom.lerp(Vector2.ONE * target_zoom, 5.0 * delta)

func _on_back_button_pressed() -> void:
	Manager.scene.change_scene("res://scenes/main_menu.tscn")
