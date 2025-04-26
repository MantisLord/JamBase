extends Node3D

var recoil_amount: Vector3 = Vector3(0.15, 0.05, 0.0)
var snap_amount: float = 8.0
var speed: float = 4.0

var current_rotation: Vector3
var target_rotation: Vector3

func _process(delta: float) -> void:
	target_rotation = lerp(target_rotation, Vector3.ZERO, speed * delta)
	current_rotation = lerp(current_rotation, target_rotation, snap_amount * delta)
	basis = Quaternion.from_euler(current_rotation)

func add_recoil(weapon: Weapon) -> void:
	recoil_amount = weapon.recoil_camera_amount
	snap_amount = weapon.recoil_camera_snap_amount
	speed = weapon.recoil_camera_speed
	target_rotation += Vector3(recoil_amount.x, randf_range(-recoil_amount.y, recoil_amount.y), randf_range(-recoil_amount.z, recoil_amount.z))
