extends CharacterBody3D
class_name Unit

@export var max_health: int = 10
@export var current_health: int = 10
@export var speed_chase: float = 4.0
@export var speed_wander: float = 1.0
@export var wander_range: float = 20.0
@export var resume_wander_min_secs: float = 4.0
@export var resume_wander_max_secs: float = 12.0
@export var idle_while_wander_chance: float = 0.1
@export var attack_range: float = 2.5
@export var damage_dealt: int = 5
@export_enum("Idle", "Wander", "Chase", "Attack", "Dead") var state: String = "Idle"
@onready var anim_player: AnimationPlayer = get_node("AnimationPlayer")
@onready var nav_agent: NavigationAgent3D = get_node("NavigationAgent3D")
@onready var player: CharacterBody3D = get_parent().get_node("Player")

var chase_target
var first_spawned = true
var wander_target

func check_hit() -> void:
	if _target_in_range(1.0):
		chase_target.hit(damage_dealt, self)

func attack_started() -> void:
	AudioManager.play_sfx_3d("mouse_attack" + str(randi_range(1, 3)), global_transform.origin)

func attack_ended() -> void:
	if !_target_in_range() || !_can_detect_target():
		_set_state("Chase")

func death_anim_done() -> void:
	toggle_ragdoll(true)

func _target_in_range(leeway = 0.0) -> bool:
	var target
	if state == "Chase" || state == "Attack":
		target = chase_target.global_position
	else:
		target = wander_target
	return global_position.distance_to(target) < attack_range + leeway

func _ready():
	_set_state(state)
	first_spawned = false

func _set_state(new_state):
	if new_state == state and !first_spawned:
		return
	$ResumeWanderTimer.stop()
	anim_player.speed_scale = 1
	match new_state:
		"Idle":
			anim_player.play("Idle")
		"Chase":
			anim_player.speed_scale = 2
			anim_player.play("Walk")
		"Dead":
			anim_player.play("Death")
			$VisionTimer.stop()
		"Wander":
			wander_target = null
			anim_player.play("Walk")
		"Attack":
			anim_player.play("Attack")
	state = new_state

func hit(damage, attacker = null, body_part: String = ""):
	if body_part == "Head":
		AudioManager.play_sfx_3d("headshot" + str(randi_range(1, 2)), global_transform.origin)
	else:
		AudioManager.play_sfx_3d("flesh_impact_bullet" + str(randi_range(1, 5)), global_transform.origin)
	current_health -= damage
	if current_health <= 0:
		_set_state("Dead")
	elif attacker != null:
		chase_target = attacker
		_set_state("Chase")

func _process(_delta):
	if Game.debug_mode:
		$DebugLabel3D.text = "Name: %s\r\nHP: %d/%d\r\nState: %s" % [self.name, current_health, max_health, state]
	else:
		$DebugLabel3D.text = ""
	for child in %VisionArea3D.get_children():
		if child is MeshInstance3D:
			child.visible = Game.debug_mode
	match state:
		"Wander":
			if wander_target == null:
				var rand_direction = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
				var rand_distance = randf() * wander_range
				var target_pos = global_position + rand_direction * rand_distance
				var nav_map = nav_agent.get_navigation_map()
				if nav_map.is_valid():
					var snapped_position = NavigationServer3D.map_get_closest_point(nav_map, target_pos)
					wander_target = snapped_position
				nav_agent.target_position = wander_target
				player._log("%s is wandering to new random point." % self.name)
			elif wander_target != null && _target_in_range():
				wander_target = null
				if randf() < idle_while_wander_chance:
					_set_state("Idle")
					var resume_time = randf_range(resume_wander_min_secs, resume_wander_max_secs)
					%ResumeWanderTimer.wait_time = resume_time
					player._log("%s switched to temp idle state for %f secs."  % [self.name, resume_time])
					%ResumeWanderTimer.start()
					return
			_move_toward_point(nav_agent.get_next_path_position(), speed_wander, _delta)
		"Idle":
			pass
		"Chase":
			if _target_in_range():
				_set_state("Attack")
				return
			nav_agent.target_position = chase_target.global_transform.origin
			_move_toward_point(nav_agent.get_next_path_position(), speed_chase, _delta)

func _move_toward_point(point, speed, delta) -> void:
	velocity = (point - global_transform.origin).normalized() * speed
	rotation.y = lerp_angle(rotation.y, atan2(velocity.x, velocity.z), delta * 10)
	move_and_slide()

func _can_detect_target() -> bool:
	var found_target = false
	var overlaps = %VisionArea3D.get_overlapping_bodies()
	if overlaps.size() > 0:
		for overlap in overlaps:
			if overlap is Player:
				$VisionRayCast3D.look_at(overlap.global_transform.origin, Vector3.UP)
				$VisionRayCast3D.force_raycast_update()
				if $VisionRayCast3D.is_colliding():
					var collider = $VisionRayCast3D.get_collider()
					if collider.name == "Player":
						chase_target = overlap
						found_target = true
	return found_target

func _on_vision_timer_timeout() -> void:
	if state == "Idle" || state == "Wander":
		if _can_detect_target():
			_set_state("Chase")

func toggle_ragdoll(enabled: bool):
	if enabled:
		%PhysicalBoneSimulator3D.physical_bones_start_simulation()
	else:
		%PhysicalBoneSimulator3D.physical_bones_stop_simulation()

func _on_resume_wander_timer_timeout() -> void:
	_set_state("Wander")
