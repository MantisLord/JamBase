extends Node3D
class_name Door

@export var locked: bool

func is_door_closed() -> bool:
	var threshold_degrees = 3.5
	var closed_angle = 0.0
	var current_angle = $DoorRigidBody3D.rotation_degrees.y
	return abs(current_angle - closed_angle) <= threshold_degrees
	
func _process(_delta: float) -> void:
	if locked:
		if is_door_closed():
			$DoorRigidBody3D.freeze = true
	else:
		$DoorRigidBody3D.freeze = false
