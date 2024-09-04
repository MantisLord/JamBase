extends Node3D

const SPEED = 40
const PHYSICS_IMPULSE_STRENGTH = 0.01

var controlled_velocity = Vector3.ZERO

func _physics_process(delta: float) -> void:
	position += controlled_velocity * delta
	pass
	
func set_velocity(target: Vector3) -> void:
	look_at(target)
	controlled_velocity = position.direction_to(target) * SPEED
	pass

func _process(_delta: float) -> void:
	if $RayCast3D.is_colliding():
		var collider = $RayCast3D.get_collider()
		$MeshInstance3D.visible = false
		$GPUParticles3D.emitting = true
		$RayCast3D.enabled = false
		if collider is RigidBody3D:
			var impulse = -$RayCast3D.get_collision_normal() * controlled_velocity.length() * PHYSICS_IMPULSE_STRENGTH
			collider.apply_impulse(impulse, $RayCast3D.get_collision_point())
		await get_tree().create_timer(1.0).timeout
		queue_free()
		
func _on_despawn_timer_timeout() -> void:
	queue_free()
