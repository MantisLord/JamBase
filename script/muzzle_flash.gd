extends Node3D

var flash_time: float

@onready var light: OmniLight3D = $OmniLight3D
@onready var emitter: GPUParticles3D = $GPUParticles3D

func _process(_delta: float) -> void:
	$LightPosHelperMeshInstance3D.visible = Game.debug_mode
	$LightOffsetPosHelperMeshInstance3D.visible = Game.debug_mode

func add_flash(weapon: Weapon) -> void:
	$LightOffsetPosHelperMeshInstance3D.position = weapon.muzzle_flash_offset
	light.light_color = weapon.muzzle_flash_color
	light.light_energy = weapon.muzzle_flash_energy
	light.omni_range = weapon.muzzle_flash_range
	var player = Game.get_player()
	var light_clip_ray = player.get_node("Head/RecoilCameraControllerNode3D/FirstCamera3D/MuzzleLightClipRayCast3D")
	if light_clip_ray != null:
		light_clip_ray.look_at($LightPosHelperMeshInstance3D.global_transform.origin, Vector3.UP)
		light_clip_ray.force_raycast_update()
		if light_clip_ray.is_colliding():
			var collider = light_clip_ray.get_collider()
			if collider == %LightCheckArea3D:
				light.position = Vector3.ZERO
			else:
				Game.log_out("moved light by offset, raycast collision: %s" % collider.name)
				light.position = weapon.muzzle_flash_offset
		else:
			Game.log_out("moved light by offset, something went horribly wrong!")
			light.position = weapon.muzzle_flash_offset
	flash_time = weapon.muzzle_flash_time
	light.visible = true
	emitter.emitting = true
	await get_tree().create_timer(flash_time).timeout
	light.visible = false
