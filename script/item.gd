class_name Item
extends Resource

@export_enum("Pistol", "Pistol ES", "SMG", "Shotgun", "Key", "Torch", "Sledge", "Assault Rifle") var name: String
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

@export_category("Sway/Bob System")
@export_subgroup("Mouse Movement Based")
@export var sway_min: Vector2 = Vector2(-20.0, -20.0)
@export var sway_max: Vector2 = Vector2(20.0, 20.0)
@export_range(0, 0.2, 0.01) var sway_speed_position: float = 0.07
@export_range(0, 0.2, 0.01) var sway_speed_rotation: float = 0.1
@export_range(0, 0.25, 0.01) var sway_amount_position: float = 0.1
@export_range(0, 50, 0.1) var sway_amount_rotation: float = 30.0
@export_subgroup("Idle")
@export var idle_sway_adjustment: float = 10.0
@export var idle_sway_rotation_strength: float = 300.0
@export_range(0.1, 10.0, 0.1) var idle_random_sway_amount: float = 5.0
@export var idle_sway_speed: float = 1.2
@export_subgroup("In Motion")
@export var bob_speed_run: float = 7.5
@export var bob_speed_sprint: float = 11.0
@export var bob_speed_crouch: float = 4.6
@export var hbob_amount_run: float = 0.1
@export var hbob_amount_sprint: float = 0.2
@export var hbob_amount_crouch: float = 0.2
@export var vbob_amount_run: float = 0.05
@export var vbob_amount_sprint: float = 0.1
@export var vbob_amount_crouch: float = 0.1
