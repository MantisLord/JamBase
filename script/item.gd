class_name Item
extends Resource

@export_enum("Pistol", "Pistol ES", "SMG", "Shotgun", "Key", "Torch", "Sledge") var name: String
@export_file("*.png") var icon: String
@export var equip_rotation: Vector3 = Vector3(0, 90, 0)
@export var equip_position: Vector3 = Vector3(0, 0, 0)
@export var equip_shader_material0: ShaderMaterial
@export var equip_shader_material1: ShaderMaterial
@export var equip_shader_material2: ShaderMaterial
@export var scene_path: String
@export var physics_box_shape: BoxShape3D
@export var pickup_physics_box_position: Vector3 = Vector3(0.231, 0.065, 0)
@export var pickup_sound: String = "item_pickup"
@export var equip_sound: String = "item_equip"
@export var use_sound: String

@export_category("Sway System")
@export var sway_min: Vector2 = Vector2(-20.0, -20.0)
@export var sway_max: Vector2 = Vector2(20.0, 20.0)
@export_range(0, 0.2, 0.01) var sway_speed_position: float = 0.07
@export_range(0, 0.2, 0.01) var sway_speed_rotation: float = 0.1
@export_range(0, 0.25, 0.01) var sway_amount_position: float = 0.1
@export_range(0, 50, 0.1) var sway_amount_rotation: float = 30.0
