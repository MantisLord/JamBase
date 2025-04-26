extends Node3D

var recoil_amount: Vector3
var snap_amount: float
var speed: float

var current_position: Vector3
var target_position: Vector3

var recoil_amount_min_x: float
var recoil_amount_max_x: float
var recoil_amount_min_y: float
var recoil_amount_max_y: float
var recoil_amount_min_z: float
var recoil_amount_max_z: float

func _process(delta: float) -> void:
	target_position = lerp(target_position, Vector3.ZERO, speed * delta)
	current_position = lerp(current_position, target_position, snap_amount * delta)
	position = current_position

func add_recoil(weapon: Weapon) -> void:
	recoil_amount_min_x = weapon.recoil_weapon_amount_min_x
	recoil_amount_max_x = weapon.recoil_weapon_amount_max_x
	recoil_amount_min_y = weapon.recoil_weapon_amount_min_y
	recoil_amount_max_y = weapon.recoil_weapon_amount_max_y
	recoil_amount_min_z = weapon.recoil_weapon_amount_min_z
	recoil_amount_max_z = weapon.recoil_weapon_amount_max_z
	snap_amount = weapon.recoil_weapon_snap_amount
	speed = weapon.recoil_weapon_speed
	var final_x = randf_range(recoil_amount_min_x, recoil_amount_max_x)
	var final_y = randf_range(recoil_amount_min_y, recoil_amount_max_y)
	var final_z = randf_range(recoil_amount_min_z, recoil_amount_max_z)
	target_position += Vector3(final_x, final_y, final_z)
	Game.log_out("wep recoil --- x: %f, y: %f, z: %f" % [final_x, final_y, final_z])
