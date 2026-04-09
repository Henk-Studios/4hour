extends Node
class_name UtilityManager

# Settings file path
const SETTINGS_PATH := "user://game_settings.cfg"

func is_mouse_over_ui(ui_nodes: Array) -> bool:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	for ui_node in ui_nodes:
		if ui_node is Control:
			var rect: Rect2 = ui_node.get_global_rect()
			if rect.has_point(mouse_pos) and ui_node.is_visible_in_tree():
				# print("Mouse is over UI node: ", ui_node.name)	
				return true
	return false

# Settings Management

func save_setting(section: String, key: String, value: Variant) -> void:
	"""Save a setting to the game settings file"""
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH) # Load existing settings
	config.set_value(section, key, value)
	
	var err := config.save(SETTINGS_PATH)
	if err != OK:
		push_error("Failed to save setting: %s/%s" % [section, key])

func load_setting(section: String, key: String, default_value: Variant) -> Variant:
	"""Load a setting from the game settings file"""
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	
	if err == OK:
		return config.get_value(section, key, default_value)
	else:
		return default_value

func has_setting(section: String, key: String) -> bool:
	"""Check if a setting exists"""
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	
	if err == OK:
		return config.has_section_key(section, key)
	return false