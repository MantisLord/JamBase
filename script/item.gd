class_name Item
extends Resource

@export var name: String = "default item"
@export_file("*.png") var icon: String
@export var equip_rotation_y_offset: int = 90
@export var equip_position: Vector3 = Vector3(0, 0, 0)
@export var scene_path: String
@export var display_scale: Vector3 = Vector3(1, 1, 1)
@export var pickup_rotation: Vector3 = Vector3(90, 45, 0)
@export var pickup_collider_size: Vector3 = Vector3(1, 1, 1)
@export var pickup_sound: String = "item_pickup"
@export var equip_sound: String = "item_equip"
