class_name Weapon
extends Item

@export var max_clip_size: int = 12
@export var left_in_clip: int = 12
@export var total_ammo: int = 36
@export var is_automatic: bool = false
@export var fire_rate = 0.3
@export var shoot_sound: String = "shoot_pistol"
@export var clip_empty_sound: String = "clip_empty"
@export var reload_sound: String = "reload_pistol"
