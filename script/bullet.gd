extends Node3D

const SPEED = 40
const PHYSICS_IMPULSE_STRENGTH = 0.01
const DAMAGE = 2

var controlled_velocity = Vector3.ZERO
var shooter

func _physics_process(delta: float) -> void:
	position += controlled_velocity * delta
	
func setup(target: Vector3, bullet_owner) -> void:
	shooter = bullet_owner
	look_at(target)
	controlled_velocity = position.direction_to(target) * SPEED

func _process(_delta: float) -> void:
	if $RayCast3D.is_colliding():
		var collider = $RayCast3D.get_collider()
		$MeshInstance3D.visible = false
		$GPUParticles3D.emitting = true
		$RayCast3D.enabled = false
		if collider is RigidBody3D:
			var impulse = -$RayCast3D.get_collision_normal() * controlled_velocity.length() * PHYSICS_IMPULSE_STRENGTH
			collider.apply_impulse(impulse, $RayCast3D.get_collision_point())
		if collider is BodyPart:
			var topmost_parent = collider
			while topmost_parent.get_parent() != null:
				topmost_parent = topmost_parent.get_parent()
				if topmost_parent is Unit:
					topmost_parent.hit(DAMAGE * collider.damage_multiplier, shooter, collider.part_name)
					if shooter is Player:
						shooter._log("%s's bullet hit %s's %s for %f damage." % [shooter.name, topmost_parent.name, collider.part_name, DAMAGE * collider.damage_multiplier])
		await get_tree().create_timer(1.0).timeout
		queue_free()

func _on_despawn_timer_timeout() -> void:
	queue_free()
