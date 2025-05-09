class_name Weapon
extends Item

@export var max_clip_size: int = 12
@export var left_in_clip: int = 12
@export var total_ammo: int = 36
@export var projectile_based: bool = false
@export var projectile_speed: float = 40.0
@export var is_automatic: bool = false
@export var fire_rate = 0.3
@export var clip_empty_sound: String = "clip_empty"
@export var reload_sound: String = "reload_pistol"
@export var damage_min: float = 2.0
@export var damage_max: float = 2.0
@export var physics_impulse_strength: float = 0.02

@export_subgroup("Muzzle Flash")
@export var muzzle_flash_time: float = 0.05
@export var muzzle_flash_color: Color = Color(0.92, 0.90, 0.47)
@export var muzzle_flash_range: float = 6.5
@export var muzzle_flash_energy: float = 3.0
@export var muzzle_flash_offset: Vector3 = Vector3.ZERO

@export_subgroup("Recoil")
@export var recoil_camera_amount: Vector3 = Vector3(0.15, 0.05, 0.0)
@export var recoil_camera_snap_amount: float = 8.0
@export var recoil_camera_speed: float = 4.0
@export var recoil_weapon_amount_min_x: float = -0.05
@export var recoil_weapon_amount_max_x: float = 0.05
@export var recoil_weapon_amount_min_y: float = 0.05
@export var recoil_weapon_amount_max_y: float = 0.15
@export var recoil_weapon_amount_min_z: float = -0.25
@export var recoil_weapon_amount_max_z: float = -0.1
@export var recoil_weapon_snap_amount: float = 10.0
@export var recoil_weapon_speed: float = 20.0
