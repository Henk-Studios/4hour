extends Area2D

@export var type: String = "health"

@onready var polygon = $Polygon2D

func _ready():
	# Randomize type on spawn
	var types = ["health", "bullet_speed", "bullet_rate"]
	type = types[randi() % types.size()]
	
	match type:
		"health":
			polygon.color = Color(0, 1, 0) # Green for health
		"bullet_speed":
			polygon.color = Color(0, 0, 1) # Blue for speed
		"bullet_rate":
			polygon.color = Color(1, 1, 0) # Yellow for rate
			
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	print("Upgrade of type ", type, " picked up by ", body.name)
	if body is Player:
		body.pickup_upgrade(type)
		queue_free()
