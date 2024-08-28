extends Node3D

const speed = 40
var controlled_velocity = Vector3.ZERO

func _physics_process(delta: float) -> void:
	position += controlled_velocity * delta
	pass
	
func set_velocity(target: Vector3) -> void:
	look_at(target)
	controlled_velocity = position.direction_to(target) * speed
	pass

func _process(_delta: float) -> void:
	if $RayCast3D.is_colliding():
		$MeshInstance3D.visible = false
		$GPUParticles3D.emitting = true
		$RayCast3D.enabled = false
		queue_free()
		
func _on_despawn_timer_timeout() -> void:
	queue_free()
