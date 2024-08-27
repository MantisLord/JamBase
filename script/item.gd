class_name Item
extends Resource

@export_enum("Pistol", "SMG", "Shotgun", "Key") var name: String
@export_file("*.png") var icon: String
@export var equip_rotation_y_offset: int = 90
@export var equip_position: Vector3 = Vector3(0, 0, 0)
@export var scene_path: String
#@export var display_scale: Vector3 = Vector3(0.4, 0.4, 0.4)
#@export var pickup_rotation: Vector3 = Vector3(90, 0, 0)
#@export var pickup_interact_box_size: Vector3 = Vector3(1, 1, 1)
@export var pickup_physics_box_size: Vector3 = Vector3(0.714, 0.435, 0.12)
@export var pickup_physics_box_position: Vector3 = Vector3(0.231, 0.065, 0)

#@export var pickup_collision_shape: Resource
#@export var pickup_collision_rotation: Vector3 = Vector3(180, 0, 0)
#@export var pickup_collision_scale: Vector3 = Vector3(40, 40, 40)

@export var pickup_sound: String = "item_pickup"
@export var equip_sound: String = "item_equip"
