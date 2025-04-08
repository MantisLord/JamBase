class_name Item
extends Resource

@export_enum("Pistol", "Pistol ES", "SMG", "Shotgun", "Key", "Torch", "Sledge") var name: String
@export_file("*.png") var icon: String
@export var equip_rotation_y_offset: int = 90
@export var equip_position: Vector3 = Vector3(0, 0, 0)
@export var scene_path: String
@export var physics_box_shape: BoxShape3D
@export var pickup_physics_box_position: Vector3 = Vector3(0.231, 0.065, 0)
@export var pickup_sound: String = "item_pickup"
@export var equip_sound: String = "item_equip"
@export var use_sound: String
