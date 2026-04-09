extends Node

# Main autoload singleton for global access to managers
# Manager references
@onready var audio: AudioManager
@onready var utility: UtilityManager
@onready var scene: SceneManager


func _ready():
	setup_managers()

	# wait 1 frame
	await get_tree().process_frame
	
	# Load the initial scene (main menu) with loading screen
	if scene:
		scene.load_initial_scene()
	else:
		push_error("SceneManager not found in Main node!")

func setup_managers():
	audio = get_node("/root/Main/AudioManager")
	utility = get_node("/root/Main/UtilityManager")
	scene = get_node("/root/Main/SceneManager")