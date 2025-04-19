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
@export var damage_dealt_min: int = 1
@export var damage_dealt_max: int = 5
@export var sounds_wound: Array[String] = ["flesh_impact_bullet1", "flesh_impact_bullet2", "flesh_impact_bullet3", "flesh_impact_bullet4", "flesh_impact_bullet5"]
@export var sounds_critical_wound: Array[String] = ["headshot1", "headshot2"]
@export var sounds_attack: Array[String] = ["mouse_attack1", "mouse_attack2", "mouse_attack3"]
@export var sounds_death: Array[String] = ["human_death1", "human_death2", "human_death3", "human_death4", "human_death5", "human_death6"]
@export_enum("Idle", "Wander", "Chase", "Attack", "Dead") var state: String = "Idle"
@export_enum("Humanity", "SewerBeasts", "Passive", "Defensive", "Aggressive") var faction: String = "Aggressive"

@onready var anim_player: AnimationPlayer = get_node("AnimationPlayer")
@onready var nav_agent: NavigationAgent3D = get_node("NavigationAgent3D")

var chase_target
var first_spawned = true
var wander_target
var spawn_state

func check_hit() -> void:
	if _target_in_range(1.0) && _detect_target() == chase_target:
		chase_target.hit(randi_range(damage_dealt_min, damage_dealt_max), self)

func attack_started() -> void:
	if sounds_attack.size() > 0:
		AudioManager.play_sfx_3d(Game.get_rand_str(sounds_attack), global_transform.origin)

func attack_ended() -> void:
	if !_target_in_range() || _detect_target() != chase_target:
		_set_state("Chase")

func death_anim_done() -> void:
	toggle_ragdoll(true)

func _target_in_range(leeway = 0.0) -> bool:
	var target
	if state == "Chase" || state == "Attack":
		target = chase_target.global_position
	else:
		target = wander_target
	if target == null:
		return false
	return global_position.distance_to(target) < attack_range + leeway

func _ready():
	_set_state(state)
	spawn_state = state
	first_spawned = false

func _set_state(new_state):
	if new_state == state and !first_spawned:
		return
	$ResumeWanderTimer.stop()
	anim_player.speed_scale = 1
	match new_state:
		"Idle":
			anim_player.stop()
			if anim_player.has_animation("Idle"):
				anim_player.play("Idle")
		"Chase":
			anim_player.speed_scale = 2
			anim_player.play("Walk")
		"Dead":
			Game.log_out("%s died." % self.name)
			if sounds_death.size() > 0:
				AudioManager.play_sfx_3d(Game.get_rand_str(sounds_death), global_transform.origin)
			if anim_player.has_animation("Death"):
				anim_player.play("Death")
			else:
				anim_player.stop()
				toggle_ragdoll(true)
			$VisionTimer.stop()
		"Wander":
			wander_target = null
			anim_player.play("Walk")
		"Attack":
			anim_player.stop()
	state = new_state

func hit(damage, attacker = null, body_part: String = ""):
	if body_part == "Head":
		if sounds_critical_wound.size() > 0:
			AudioManager.play_sfx_3d(Game.get_rand_str(sounds_critical_wound), global_transform.origin)
	else:
		if sounds_wound.size() > 0:
			AudioManager.play_sfx_3d(Game.get_rand_str(sounds_wound), global_transform.origin)
	Game.log_out("%s hit %s for %d damage." % [attacker.name, self.name, damage])
	current_health -= damage
	if current_health <= 0:
		_set_state("Dead")
	elif attacker != null:
		chase_target = attacker
		_set_state("Chase")

func _process(_delta):
	if Game.debug_mode:
		$DebugLabel3D.visible = true
		$DebugLabel3D.text = "Name: %s\r\nHP: %d/%d\r\nState: %s" % [self.name, current_health, max_health, state]
	else:
		$DebugLabel3D.visible = false
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
				Game.log_out("%s is wandering to new random point. %s" % [self.name, nav_agent.target_position])
			elif wander_target != null:
				if _target_in_range():
					wander_target = null
					Game.log_out("%s reached wander point. %s" % [self.name, nav_agent.target_position])
					if randf() < idle_while_wander_chance:
						_set_state("Idle")
						var resume_time = randf_range(resume_wander_min_secs, resume_wander_max_secs)
						%ResumeWanderTimer.wait_time = resume_time
						Game.log_out("%s switched to temp idle state for %f secs." % [self.name, resume_time])
						%ResumeWanderTimer.start()
						return
				else:
					_move_toward_point(nav_agent.get_next_path_position(), speed_wander, _delta)
		"Idle":
			pass
		"Attack":
			if _target_dead(chase_target):
				_reset()
			if !anim_player.is_playing():
				anim_player.play("Attack")
				look_at(Vector3(chase_target.global_position.x, global_position.y, chase_target.global_position.z), Vector3.UP)
				rotate_y(PI) # why are they backwards/flipped 180 after look_at?
		"Chase":
			if _target_dead(chase_target):
				_reset()
			if _target_in_range():
				_set_state("Attack")
				return
			nav_agent.target_position = chase_target.global_transform.origin
			_move_toward_point(nav_agent.get_next_path_position(), speed_chase, _delta)

func _reset():
	Game.log_out("%s is done engaging %s. Going back to spawn state %s." % [self.name, chase_target.name, spawn_state])
	_set_state(spawn_state)

func _target_dead(target) -> bool:
	if target is Unit:
		return target.state == "Dead"
	if target is Player:
		return target.current_health <= 0
	return false

func _move_toward_point(point, speed, delta) -> void:
	velocity = (point - global_transform.origin).normalized() * speed
	rotation.y = lerp_angle(rotation.y, atan2(velocity.x, velocity.z), delta * 10)
	move_and_slide()

# Faction		CanAttack
# 1 Humanity	SewerBeasts, Player (if attacked)
# 2 SewerBeasts	Humanity, Player
# 3 Passive		None, runs away if attacked by any
# 4 Defensive	All, only if attacked
# 5 Aggressive	All
func _is_aggressive_to(target) -> bool:
	match faction:
		"Aggressive":
			return true
		"SewerBeasts":
			if target is Player:
				return true
			if target is Unit:
				if target.faction in ["Humanity"]:
					return true
		"Humanity":
			if target is Unit:
				if target.faction in ["SewerBeasts"]:
					return true
	return false

func _get_body_part_parent(body_part):
	return body_part.get_parent().get_parent().get_parent().get_parent() # find a better way...

func _detect_target():
	var overlaps = %VisionArea3D.get_overlapping_bodies()
	if overlaps.size() > 0:
		for overlap in overlaps:
			var root_target = null
			if overlap is BodyPart:
				root_target = _get_body_part_parent(overlap)
			if overlap is Player:
				root_target = overlap
			if root_target != null:
				if state == "Attack" && root_target != chase_target:
					continue
				if root_target is Unit && root_target.state == "Dead":
					continue
				%VisionRayCast3D.look_at(overlap.global_transform.origin, Vector3.UP)
				%VisionRayCast3D.force_raycast_update()
				if %VisionRayCast3D.is_colliding():
					var collider = %VisionRayCast3D.get_collider()
					if collider is BodyPart:
						if _get_body_part_parent(collider) == root_target:
							return root_target
					if collider is Player:
						return root_target
	return null

func _on_vision_timer_timeout() -> void:
	if state == "Idle" || state == "Wander":
		var target = _detect_target()
		if target != null:
			if _is_aggressive_to(target) && !_target_dead(target):
				Game.log_out("%s is engaging %s" % [self.name, target.name])
				chase_target = target
				_set_state("Chase")

func toggle_ragdoll(enabled: bool):
	if enabled:
		%PhysicalBoneSimulator3D.physical_bones_start_simulation()
	else:
		%PhysicalBoneSimulator3D.physical_bones_stop_simulation()

func _on_resume_wander_timer_timeout() -> void:
	_set_state("Wander")
