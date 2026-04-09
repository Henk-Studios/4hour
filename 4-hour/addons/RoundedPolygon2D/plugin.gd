@tool
extends EditorPlugin

const SCRIPT = preload("res://addons/RoundedPolygon2D/RoundedPolygon2D.gd")
const ICON = preload("res://addons/RoundedPolygon2D/RoundedPolygon2D.svg")

func _enter_tree():
	add_custom_type("RoundedPolygon2D", "Polygon2D", SCRIPT, ICON)

func _exit_tree():
	remove_custom_type("RoundedPolygon2D")
