extends Node3D

var flash_time: float

@onready var light: OmniLight3D = $OmniLight3D
@onready var emitter: GPUParticles3D = $GPUParticles3D

func add_flash(weapon: Weapon) -> void:
	light.light_color = weapon.muzzle_flash_color
	light.light_energy = weapon.muzzle_flash_energy
	light.omni_range = weapon.muzzle_flash_range
	light.position = weapon.muzzle_flash_position
	$LightPosHelperMeshInstance3D.position = weapon.muzzle_flash_position
	flash_time = weapon.muzzle_flash_time
	light.visible = true
	emitter.emitting = true
	await get_tree().create_timer(flash_time).timeout
	light.visible = false
