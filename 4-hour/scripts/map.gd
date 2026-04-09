extends Node2D
class_name Map

const PLAYER_SCENE = preload("res://scenes/player.tscn")
@export var grid: GridContainer

var camera_targets: Array[Dictionary] = []

var active_player_stats: Array[Dictionary] = []
var start_time: float = 0.0
var elapsed_time: float = 0.0
var game_over: bool = false
var game_over_ui: Control
var match_time: float = 10.0
var pvp_activated: bool = false

func setup(params: Dictionary) -> void:
	print("Map scene setup with params: ", params)
	
	if params.has("match_time"):
		match_time = params["match_time"]
		
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
			
			active_player_stats.append({
				"player": player,
				"player_index": player.player_index,
				"time_survived": 0.0,
				"dead": false,
				"color": player.COLORS[player.player_index % player.COLORS.size()]
			})
			
	Manager.pvp_enabled = false
	Manager.scene.finish_loading()

func _process(delta: float) -> void:
	if not game_over:
		elapsed_time += delta
		
		if not pvp_activated:
			match_time -= delta
			var timer_label = $UI/TimerLabel
			if is_instance_valid(timer_label):
				if match_time <= 0:
					match_time = 0
					_activate_pvp()
				else:
					var minutes = int(match_time) / 60
					var seconds = int(match_time) % 60
					timer_label.text = "%02d:%02d" % [minutes, seconds]
					
		_check_players_alive()

	for item in camera_targets:
		if is_instance_valid(item.target) and is_instance_valid(item.camera):
			var prev_position = item.camera.position
			item.camera.position = item.camera.position.lerp(item.target.position, 5.0 * delta)
			
			# Calculate camera movement speed and adjust zoom
			var movement_speed = prev_position.distance_to(item.camera.position) / delta if delta > 0 else 0.0
			var zoom_factor = inverse_lerp(0.0, 1000, movement_speed)
			var target_zoom = lerp(1.0, 0.5, zoom_factor)
			item.camera.zoom = item.camera.zoom.lerp(Vector2.ONE * target_zoom, 5.0 * delta)

func _check_players_alive() -> void:
	var alive_count = 0
	
	for stat in active_player_stats:
		if not stat["dead"]:
			if is_instance_valid(stat["player"]):
				alive_count += 1
				stat["time_survived"] = elapsed_time
			else:
				stat["dead"] = true

	if active_player_stats.size() > 0:
		if pvp_activated and alive_count <= 1:
			_show_game_over()
		elif not pvp_activated and alive_count == 0:
			_show_game_over()

func _show_game_over() -> void:
		game_over = true

		$UI/GameOverPanel.show()

		# Sort players by survival time descending
		active_player_stats.sort_custom(func(a, b): return a["time_survived"] > b["time_survived"])

		var title = $UI/GameOverPanel/VBoxContainer/TitleLabel
		if active_player_stats.size() > 0:
				title.text = "Player %d won!" % (active_player_stats[0]["player_index"] + 1)
				title.modulate = active_player_stats[0]["color"]

		var player_list = $UI/GameOverPanel/VBoxContainer/PlayerList
		for child in player_list.get_children():
				child.queue_free()

		for i in range(active_player_stats.size()):
				var stat = active_player_stats[i]
				var l = Label.new()
				var p_name = "Player " + str(stat["player_index"] + 1)
				var t = "%.1f seconds" % stat["time_survived"]
				l.text = "%d. %s - Survived %s" % [(i + 1), p_name, t]
				l.modulate = stat["color"]
				player_list.add_child(l)

func _on_back_button_pressed() -> void:
	Manager.scene.change_scene("res://scenes/main_menu.tscn")

func _activate_pvp() -> void:
	Manager.pvp_enabled = true
	pvp_activated = true
	var timer_label = $UI/TimerLabel
	if is_instance_valid(timer_label):
		timer_label.text = "PVP ENABLED"
		timer_label.add_theme_color_override("font_color", Color.RED)
	
	# Find and remove all enemies and spawners recursively
	var all_nodes = get_tree().current_scene.find_children("*", "", true, false)
	for node in all_nodes:
		if node is Enemy or node is EnemySpawner or node is EnemyBullet:
			node.queue_free()
