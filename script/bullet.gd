extends Node3D

var speed = 40.0
var physics_impulse_strength = 0.01
var min_damage = 2.0
var max_damage = 2.0

var controlled_velocity = Vector3.ZERO
var shooter
var source_weapon

func _physics_process(delta: float) -> void:
	position += controlled_velocity * delta
	
func setup(target: Vector3, bullet_owner, weapon: Weapon) -> void:
	source_weapon = weapon 
	shooter = bullet_owner
	look_at(target)
	controlled_velocity = position.direction_to(target) * speed

func _process(_delta: float) -> void:
	if $RayCast3D.is_colliding():
		var collider = $RayCast3D.get_collider()
		$MeshInstance3D.visible = false
		$GPUParticles3D.emitting = true
		$RayCast3D.enabled = false
		Game.handle_physics_collision($RayCast3D, shooter, collider, controlled_velocity, source_weapon)
		await get_tree().create_timer(1.0).timeout
		queue_free()

func _on_despawn_timer_timeout() -> void:
	queue_free()
