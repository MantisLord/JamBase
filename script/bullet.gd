extends Node3D

var speed = 40.0
var physics_impulse_strength = 0.01
var min_damage = 2.0
var max_damage = 2.0

var controlled_velocity = Vector3.ZERO
var shooter

func _physics_process(delta: float) -> void:
	position += controlled_velocity * delta
	
func setup(target: Vector3, bullet_owner, weapon: Weapon) -> void:
	speed = weapon.projectile_speed
	physics_impulse_strength = weapon.physics_impulse_strength
	min_damage = weapon.damage_min
	max_damage = weapon.damage_max
	shooter = bullet_owner
	look_at(target)
	controlled_velocity = position.direction_to(target) * speed

func _calc_impulse() -> Vector3:
	return -$RayCast3D.get_collision_normal() * controlled_velocity.length() * physics_impulse_strength

func _process(_delta: float) -> void:
	if $RayCast3D.is_colliding():
		var collider = $RayCast3D.get_collider()
		$MeshInstance3D.visible = false
		$GPUParticles3D.emitting = true
		$RayCast3D.enabled = false
		if collider is RigidBody3D:
			collider.apply_impulse(_calc_impulse(), $RayCast3D.get_collision_point())
		if collider is BodyPart:
			var topmost_parent = collider
			while topmost_parent.get_parent() != null:
				topmost_parent = topmost_parent.get_parent()
				if topmost_parent is PhysicalBoneSimulator3D:
					if topmost_parent.is_simulating_physics():
						collider.apply_impulse(_calc_impulse(), $RayCast3D.get_collision_point())
				if topmost_parent is Unit:
					var final_dmg = randf_range(min_damage, max_damage) * collider.damage_multiplier
					topmost_parent.hit(final_dmg, shooter, collider.part_name)
					if shooter is Player:
						shooter._log("%s's bullet hit %s's %s for %f damage." % [shooter.name, topmost_parent.name, collider.part_name, final_dmg])
		await get_tree().create_timer(1.0).timeout
		queue_free()

func _on_despawn_timer_timeout() -> void:
	queue_free()
