extends BulletBase
class_name PlayerBullet

func _ready():
	if Manager.pvp_enabled:
		# include player collision
		set_collision_mask_value(3, true)