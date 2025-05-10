extends Sprite3D

@export var speed: float = 2.0

func _process(_delta: float) -> void:
	if Input.is_action_pressed("left"):
		rotate_y(deg_to_rad(-speed))
	elif Input.is_action_pressed("right"):
		rotate_y(deg_to_rad(speed))
