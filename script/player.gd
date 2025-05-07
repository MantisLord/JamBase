extends CharacterBody3D
class_name Player

const SPEED_RUN = 5.0
const SPEED_SPRINT = 8.0
const SPEED_CROUCH = 3.0
const SPEED_AIR = 0.5
const SPEED_GROUND_ACCEL = 10.0
const SPEED_GROUND_DECCEL = 7.0
const SPEED_HEAD = 7.0
const SPEED_CAMERA = 8.0
const JUMP_VELOCITY = 4.5
const MIN_ANGLE_VIEW = -75
const MAX_ANGLE_VIEW = 75
const HEAD_BOB_FREQ = 2.4
const HEAD_BOB_AMP = 0.08
const FOV_CHANGE = 1.5
const PHYSICS_IMPULSE_STRENGTH: float = 0.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var play_footsteps_sfx = false
var speed = 0.0
var head_bob_time = 0.0

var max_health: int = 100
var current_health: int = 100

var inventory = []
var equipped_item_index = -1
var equipped_item_instance
var item_panel = preload("res://scene/item_panel.tscn")
var item_pickup = preload("res://scene/item_pickup.tscn")

var bullet = preload("res://scene/bullet.tscn")

var bullet_debug = preload("res://scene/bullet_debug.tscn")

@onready var current_cam: Camera3D = %FirstCamera3D
var current_cam_index: int = 0

var is_crouching: bool = false
var need_landing_anim: bool = false

var mouse_movement: Vector2

var bullethole = preload("res://scene/bullethole.tscn")

func hit(damage, attacker):
	current_health -= damage
	Game.log_out("%s hit player for %d damage. Player has %d HP remaining." % [attacker.name, damage, current_health])
	AudioManager.play_sfx(AudioManager.sfx_take_damage)

func _pick_up_item(item_res) -> void:
	if !%InventoryPanelContainer.visible:
		%InventoryPanelContainer.visible = true
	inventory.append(item_res)
	var panel = item_panel.instantiate()
	panel.get_node("TextureRect").texture = load(item_res.icon)
	var action_name = "selectitem%d" % int(inventory.size())
	var key_name = %Menu.get_key_name_from_action(action_name)
	Game.log_out("got key name %s for action name %s" % [key_name, action_name])
	panel.get_node("BindLabel").text = key_name
	%InventoryHBoxContainer.add_child(panel)
	Game.log_out("picked up %s" % item_res.name)
	AudioManager.play_sfx_by_name(item_res.pickup_sound)
	if equipped_item_index == -1:
		Game.log_out("auto-equipping %s" % item_res.name)
		_equip_item(inventory.size() - 1)

func _drop_item(item_res) -> void:
	if %AnimationPlayer.is_playing():
		return
	var dropping_index = equipped_item_index
	await _unequip_item()
	var pickup = item_pickup.instantiate()
	pickup.item_res = item_res
	get_tree().root.add_child(pickup)
	for mesh_instance in pickup.find_children("*", "MeshInstance3D"):
		set_shader_param_on_mesh(mesh_instance, "disable_effect", true)
	pickup.global_position = %DropItemNode3D.global_position
	inventory.remove_at(dropping_index)
	var panel = %InventoryHBoxContainer.get_child(dropping_index)
	%InventoryHBoxContainer.remove_child(panel)
	panel.queue_free()
	var action_counter = 1
	for child in %InventoryHBoxContainer.get_children():
		var action_name = "selectitem%d" % action_counter
		var key_name = %Menu.get_key_name_from_action(action_name)
		child.get_node("BindLabel").text = key_name
		action_counter += 1
	Game.log_out("dropped %s " % item_res.name)

func _unequip_item() -> void:
	if %AnimationPlayer.is_playing():
		return
	if equipped_item_index != -1:
		Game.log_out("unequipped %s" % inventory[equipped_item_index].name)
		AudioManager.play_sfx_by_name(inventory[equipped_item_index].equip_sound)
		%AnimationPlayer.play("lower")
		await %AnimationPlayer.animation_finished
		for child in %EquippedItemNode3D.get_children():
			if child.name == "weapon_rot_tracker":
				%EquippedItemNode3D.remove_child(child)
		equipped_item_instance.queue_free()
		equipped_item_instance = null
		equipped_item_index = -1

func _equip_item(new_index) -> void:
	if %AnimationPlayer.is_playing():
		return
	if equipped_item_index != -1:
		await _unequip_item()
	var item_res = inventory[new_index]
	var item_scene = load(item_res.scene_path)
	equipped_item_instance = item_scene.instantiate()
	
	var rotation_parent = Node3D.new()
	rotation_parent.name = "weapon_rot_tracker"
	%EquippedItemNode3D.add_child(rotation_parent)
	rotation_parent.rotation_degrees.y = %Head.rotation.y + item_res.equip_rotation.y
	equipped_item_instance.position = item_res.equip_position
	#equipped_item_instance.rotation_degrees = item_res.equip_rotation
	rotation_parent.add_child(equipped_item_instance)
	%AnimationPlayer.play("raise")
	AudioManager.play_sfx_by_name(inventory[new_index].equip_sound)
	for mesh_instance in equipped_item_instance.find_children("*", "MeshInstance3D"):
		set_shader_param_on_mesh(mesh_instance, "disable_effect", false)
	equipped_item_index = new_index
	Game.log_out("equipped %s" % inventory[equipped_item_index].name)

func set_shader_param_on_mesh(mesh_instance: MeshInstance3D, param_name: String, value):
	var mesh = mesh_instance.mesh
	if mesh == null:
		return
	var surface_count = mesh.get_surface_count()
	for i in range(surface_count):
		var material = mesh.surface_get_material(i)
		if material is ShaderMaterial:
			material.set_shader_parameter(param_name, value)

func _use(item):
	if item is Weapon:
		_shoot(item)
	else:
		match item.name:
			"Key":
				var item_anim_player = equipped_item_instance.get_node("AnimationPlayer")
				if !item_anim_player.is_playing():
					item_anim_player.play("use")
					await get_tree().create_timer(1.0).timeout
					if %InteractRayCast3D.is_colliding():
						var collider = %InteractRayCast3D.get_collider().get_parent()
						if collider is Door:
							collider.locked = !collider.locked
							AudioManager.play_sfx_by_name(item.use_sound)
							var action_word = "unlock"
							if collider.locked:
								action_word = "lock"
							Game.log_out("Used key to %s door." % action_word)
			"Torch":
				var light = equipped_item_instance.get_node("OmniLight3D")
				var emitter = equipped_item_instance.get_node("GPUParticles3D")
				if light.light_energy == 2:
					light.light_energy = 0
					emitter.emitting = false
				else:
					light.light_energy = 2
					emitter.emitting = true

func _shoot(weapon):
	# can't fire if already firing
	if %ShootCooldownTimer.time_left > 0:
		return
	%ShootCooldownTimer.wait_time = weapon.fire_rate
	%ShootCooldownTimer.start()
	if weapon.max_clip_size == 0: # melee
		equipped_item_instance.get_node("AnimationPlayer").play("swing")
		AudioManager.play_sfx_by_name(weapon.use_sound)
	elif weapon.left_in_clip > 0:
		%RecoilCameraControllerNode3D.add_recoil(weapon)
		if equipped_item_instance.has_node("RecoilWeaponControllerNode3D"):
			var recoil_wep = equipped_item_instance.get_node("RecoilWeaponControllerNode3D")
			recoil_wep.add_recoil(weapon)
		if equipped_item_instance.has_node("MuzzleNode3D"):
			var muzzle = equipped_item_instance.get_node("MuzzleNode3D")
			muzzle.add_flash(weapon)
		equipped_item_instance.get_node("AnimationPlayer").play("fire")
		AudioManager.play_sfx_by_name(weapon.use_sound)
		weapon.left_in_clip -= 1

		if !weapon.projectile_based:
			var space_state = %FirstCamera3D.get_world_3d().direct_space_state
			var screen_center = get_viewport().size / 2
			var origin = %FirstCamera3D.project_ray_origin(screen_center)
			var end = origin + %FirstCamera3D.project_ray_normal(screen_center) * 1000
			var query = PhysicsRayQueryParameters3D.create(origin, end)
			query.collide_with_bodies = true
			var result = space_state.intersect_ray(query)
			if result:
				var collider = result.get("collider")
				var collision_point = result.get("position")
				var normal = result.get("normal")
				Game.handle_collision(collider, normal, collision_point, self, weapon)

				var instance = bullethole.instantiate()
				collider.add_child(instance)
				instance.global_position = collision_point
				if normal == Vector3.UP or normal == Vector3.DOWN:
					instance.rotation = Vector3.ZERO
				else:
					instance.look_at(instance.global_transform.origin + normal, Vector3.UP)
					instance.rotate_object_local(Vector3.RIGHT, deg_to_rad(90))
				var fade_tween: Tween = get_tree().create_tween()
				fade_tween.tween_interval(30.0)
				fade_tween.tween_property(instance, "modulate:a", 0, 2.0)
				await fade_tween.finished
				instance.queue_free()
		else:
			var barrel_pos = equipped_item_instance.get_node("MuzzleNode3D").global_position
			var bullet_instance = bullet.instantiate()
			bullet_instance.position = barrel_pos
			var end_point = %AimRayCast3D.get_collision_point() if %AimRayCast3D.is_colliding() else %AimRayEndNode3D.global_position
			# fix the start or end point here if something is wrong?
			# like the gun pointing through a wall - collision point closer to player than the start point
			if global_transform.origin.distance_to(end_point) < global_transform.origin.distance_to(barrel_pos):
				bullet_instance.position = %AltBulletStartPoint.global_transform.origin # end_point
				Game.log_out("corrected start pos of bullet due to some issue")
			get_tree().root.add_child(bullet_instance)
			bullet_instance.setup(end_point, self, weapon)
			if Game.debug_mode:
				var debug_instance_start = bullet_debug.instantiate()
				debug_instance_start.get_node("StartMeshInstance3D").visible = true
				debug_instance_start.position = bullet_instance.position
				var debug_instance_end = bullet_debug.instantiate()
				debug_instance_end.get_node("EndMeshInstance3D").visible = true
				debug_instance_end.position = end_point
				get_tree().root.add_child(debug_instance_start)
				get_tree().root.add_child(debug_instance_end)
				await get_tree().create_timer(5).timeout
				debug_instance_end.queue_free()
				debug_instance_start.queue_free()
	else:
		AudioManager.play_sfx_by_name(weapon.clip_empty_sound)

func _reload(weapon):
	if weapon.left_in_clip == weapon.max_clip_size:
		return
	var needed = weapon.max_clip_size - weapon.left_in_clip
	var reload_amount = min(needed, weapon.total_ammo)
	if reload_amount > 0:
		var wep_anim = equipped_item_instance.get_node("AnimationPlayer")
		if wep_anim.has_animation("reload"):
			wep_anim.play("reload")
		AudioManager.play_sfx_by_name(weapon.reload_sound)
	weapon.left_in_clip += reload_amount
	weapon.total_ammo -= reload_amount

func _ready():
	%Menu.visible = false
	%Menu.get_node("%TitleMarginContainer").visible = false
	%Menu.get_node("%MainPanelContainer").size_flags_vertical = Control.SIZE_SHRINK_CENTER + Control.SIZE_EXPAND

func _handle_primary_actions():
	if Input.is_action_just_pressed("menu"):
		%Menu.visible = !%Menu.visible
		if %Menu.visible:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			AudioManager.play_sfx(AudioManager.sfx_menu_open)
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			AudioManager.play_sfx(AudioManager.sfx_menu_close)
	
	if !%AnimationPlayer.is_playing():
		for n in inventory.size():
			if Input.is_action_just_pressed("selectitem%d" % (n + 1)):
				Game.log_out("detected player selected item index %d" % n)
				if n == equipped_item_index:
					_unequip_item()
				else:
					_equip_item(n)
		if Input.is_action_just_pressed("nextitem"):
			if equipped_item_index > -1:
				var new_index = equipped_item_index
				if equipped_item_index == inventory.size() - 1:
					new_index = 0
				else:
					new_index = equipped_item_index + 1
				if new_index != equipped_item_index:
					_equip_item(new_index)
		if Input.is_action_just_pressed("previtem"):
			if equipped_item_index > -1:
				var new_index = equipped_item_index
				if equipped_item_index == 0:
					new_index = inventory.size() - 1
				else:
					new_index = equipped_item_index - 1
				if new_index != equipped_item_index:
					_equip_item(new_index)

func _update_ui():
	if Game.debug_mode:
		%DebugLabel.text = "FPS: %f" % Engine.get_frames_per_second()
		%DebugLabel.text += "\r\nmouse sensitivity: %.2f" % Game.mouse_sensitivity
		%DebugLabel.text += "\r\nplayer position: %s" % str(position)
		%DebugLabel.text += "\r\ninput mouse mode: %s" % Input.mouse_mode
		%DebugLabel.text += "\r\nis_crouching: %s" % is_crouching
		%DebugLabel.text += "\r\nfov: %.0f" % Game.fov
	else:
		%DebugLabel.text = ""
	%DebugMarginContainer.visible = Game.debug_mode
	%DebugLogMarginContainer.visible = Game.debug_mode
	%HandMeshInstance3D.visible = Game.debug_mode
	
	%HealthLabel.text = "HP: %d/%d" % [current_health, max_health]
	
	if equipped_item_index != -1:
		var equipped_item_res = inventory[equipped_item_index];
		%EquipLabel.text = "%s (%d)" % [equipped_item_res.name, equipped_item_index]
		if equipped_item_res is Weapon:
			%EquipLabel.text += "\r\nCurrent Clip (%d/%d)" % [equipped_item_res.left_in_clip, equipped_item_res.max_clip_size]
			%EquipLabel.text += "\r\nAmmo: %d" % equipped_item_res.total_ammo
	else:
		%EquipLabel.text = ""

func _handle_items():
	if equipped_item_index != -1:
		var equipped_item_res = inventory[equipped_item_index];
		if equipped_item_res is Weapon:
			if equipped_item_res.max_clip_size == 0:
				var melee_area = equipped_item_instance.find_child("MeleeArea3D")
				if melee_area.monitoring:
					var overlaps = melee_area.get_overlapping_bodies()
					for overlap in overlaps:
						#var swing_velocity = global_position.direction_to(overlap.global_position)
						Game.handle_collision(overlap, %InteractRayCast3D.get_collision_normal(), %InteractRayCast3D.get_collision_point(), self, equipped_item_res)
						melee_area.monitoring = false
		if !%Menu.visible && Input.is_action_just_pressed("drop"):
			_drop_item(equipped_item_res)
		if !%AnimationPlayer.is_playing() && !%Menu.visible:
			if equipped_item_res is Weapon && equipped_item_res.is_automatic && Input.is_action_pressed("useitem"):
				_use(equipped_item_res)
			elif Input.is_action_just_pressed("useitem"):
				_use(equipped_item_res)
			if equipped_item_res is Weapon && Input.is_action_just_pressed("reload"):
				_reload(equipped_item_res)

func _check_cams():
	if %FirstCamera3D.current:
		current_cam_index = 0
	if %ThirdCamera3D.current:
		current_cam_index = 1
	var top_down_cam = null
	if get_parent().has_node("TopDownCamera3D"):
		top_down_cam = get_parent().get_node("TopDownCamera3D")
		if top_down_cam != null and top_down_cam.current:
			current_cam_index = 2
	if Game.cam_mode != current_cam_index:
		%FirstCamera3D.current = false
		%ThirdCamera3D.current = false
		if top_down_cam != null:
			top_down_cam.current = false
		if Game.cam_mode == 0:
			%FirstCamera3D.current = true
		if Game.cam_mode == 1:
			%ThirdCamera3D.current = true
		if Game.cam_mode == 2 and top_down_cam != null:
			top_down_cam.current = true
		current_cam_index = Game.cam_mode

func _process(_delta):
	_handle_primary_actions()

	_check_cams()

	_update_ui()

	_handle_items()

	_interaction_check()

var current_focus: Interactable

func _interaction_check():
	if !%Menu.visible:
		if %InteractRayCast3D.is_colliding():
			var collider = %InteractRayCast3D.get_collider()
			if collider != null:
				var parent = collider.get_parent()
				if (parent is ItemPickup || parent is Door || parent is Trapdoor):
					collider = collider.get_parent()
			if current_focus != null && current_focus != collider:
				current_focus.unfocus()
				%InteractLabel.text = ""
			if collider is Interactable:
				current_focus = collider
				collider.focus()
				%InteractLabel.text = ""

			if collider is ItemPickup:
				%InteractLabel.text = "Press %s to pick up %s." % [%Menu.get_key_name_from_action("interact"), collider.item_res.name]
				if Input.is_action_just_pressed("interact"):
					_pick_up_item(collider.item_res)
					collider.queue_free()
					%InteractLabel.text = ""
			elif collider is Door:
				if collider.locked:
					%InteractLabel.text = "Locked."
				else:
					%InteractLabel.text = ""
			elif collider is Trapdoor:
				%InteractLabel.text = "Press %s to travel to %s." % [%Menu.get_key_name_from_action("interact"), collider.teleport_scene_name]
				if Input.is_action_just_pressed("interact"):
					Game.change_scene("sewer")
			elif collider is PushButton:
				%InteractLabel.text = "Press %s to %s." % [%Menu.get_key_name_from_action("interact"), collider.action_display]
				if Input.is_action_just_pressed("interact"):
					collider.start_press()
		elif current_focus != null:
			current_focus.unfocus()
			%InteractLabel.text = ""
	else:
		if current_focus != null:
			current_focus.unfocus()
		%InteractLabel.text = ""
	%ReticleCenterContainer.visible = false if len(%InteractLabel.text) > 0 || %Menu.visible else true 

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		$Head.rotate_y(deg_to_rad(-event.relative.x * Game.mouse_sensitivity))
		current_cam.rotate_x(deg_to_rad(-event.relative.y * Game.mouse_sensitivity))
		current_cam.rotation.x = clamp(current_cam.rotation.x, deg_to_rad(MIN_ANGLE_VIEW), deg_to_rad(MAX_ANGLE_VIEW))
		mouse_movement = event.relative

# try to fix focus issues on web (unsucessfully)
func _unhandled_input(event):
	if OS.get_name() == "Web":
		if event is InputEventMouseButton and event.pressed and %Menu.visible == false:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

var random_sway_x
var random_sway_y
var time: float = 0.0
@onready var sway_noise: NoiseTexture2D = NoiseTexture2D.new()

func _sway_item(delta) -> void:
	if equipped_item_index != -1:
		var equipped_item_res = inventory[equipped_item_index];
		if sway_noise.noise == null:
			sway_noise.noise = FastNoiseLite.new()
		mouse_movement = mouse_movement.clamp(equipped_item_res.sway_min, equipped_item_res.sway_max)
		if !play_footsteps_sfx:
			var sway_random: float = sway_noise.noise.get_noise_2d(global_position.x, global_position.y)
			var sway_random_adjusted: float = sway_random * equipped_item_res.idle_sway_adjustment
			time += delta * (equipped_item_res.idle_sway_speed * sway_random)
			random_sway_x = sin(time * 1.5 + sway_random_adjusted) / equipped_item_res.idle_random_sway_amount
			random_sway_y = sin(time - sway_random_adjusted) / equipped_item_res.idle_random_sway_amount
		else:
			random_sway_x = 0.0
			random_sway_y = 0.0
			match (speed):
				SPEED_RUN:
					_bob_item(delta, equipped_item_res.bob_speed_run, equipped_item_res.hbob_amount_run, equipped_item_res.vbob_amount_run)
				SPEED_SPRINT:
					_bob_item(delta, equipped_item_res.bob_speed_sprint, equipped_item_res.hbob_amount_sprint, equipped_item_res.vbob_amount_sprint)
				SPEED_CROUCH:
					_bob_item(delta, equipped_item_res.bob_speed_crouch, equipped_item_res.hbob_amount_crouch, equipped_item_res.vbob_amount_crouch)
		equipped_item_instance.position.x = lerp(equipped_item_instance.position.x, equipped_item_res.equip_position.x - (mouse_movement.x * equipped_item_res.sway_amount_position + random_sway_x) * delta, equipped_item_res.sway_speed_position)
		equipped_item_instance.position.y = lerp(equipped_item_instance.position.y, equipped_item_res.equip_position.y + (mouse_movement.y * equipped_item_res.sway_amount_position + random_sway_y) * delta, equipped_item_res.sway_speed_position)
		equipped_item_instance.get_parent().rotation_degrees.y = lerp(equipped_item_instance.get_parent().rotation_degrees.y, equipped_item_res.equip_rotation.y + (mouse_movement.x * equipped_item_res.sway_amount_rotation + (random_sway_y * equipped_item_res.idle_sway_rotation_strength)) * delta, equipped_item_res.sway_speed_rotation)
		equipped_item_instance.rotation_degrees.x = lerp(equipped_item_instance.rotation_degrees.x, equipped_item_res.equip_rotation.x - (mouse_movement.y * equipped_item_res.sway_amount_rotation + (random_sway_x * equipped_item_res.idle_sway_rotation_strength)) * delta, equipped_item_res.sway_speed_rotation)

func _bob_item(delta, bob_speed: float, hbob_amount: float, vbob_amount: float) -> void:
	if equipped_item_index != -1 and is_on_floor():
		time += delta
		equipped_item_instance.position.x = sin(time  * bob_speed) * hbob_amount
		equipped_item_instance.position.y = abs(cos(time * bob_speed) * vbob_amount)

func _physics_process(delta):
	_sway_item(delta)
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		play_footsteps_sfx = false
		if !need_landing_anim:
			need_landing_anim = true
	elif need_landing_anim:
		%AnimationPlayer.play("jump_end")
		need_landing_anim = false

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor() and !is_crouching:
		velocity.y = JUMP_VELOCITY
		AudioManager.play_sfx(AudioManager.sfx_jump)
		play_footsteps_sfx = false
		%AnimationPlayer.play("jump_start")
		need_landing_anim = true

	# Get the input direction.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = ($Head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Handle move speed.
	if Input.is_action_pressed("crouch"):
		speed = SPEED_CROUCH
		AudioManager.sfx_footsteps.audio_player.pitch_scale = 0.6
		if !is_crouching:
			%AnimationPlayer.play("crouch", -1, SPEED_HEAD)
			is_crouching = true
	elif !%HeadCollisionRayCast3D.is_colliding():
		if is_crouching:
			%AnimationPlayer.play("crouch", -1, -SPEED_HEAD, true)
			is_crouching = false
		if Input.is_action_pressed("sprint"):
			speed = SPEED_SPRINT
			AudioManager.sfx_footsteps.audio_player.pitch_scale = 1.6
		else:
			speed = SPEED_RUN
			AudioManager.sfx_footsteps.audio_player.pitch_scale = 1.0

	# Handle the movement/deceleration.
	if is_on_floor():
		if direction:
			play_footsteps_sfx = true
			velocity.x = lerp(velocity.x, direction.x * speed, delta * SPEED_GROUND_ACCEL)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * SPEED_GROUND_ACCEL)
		else:
			play_footsteps_sfx = false
			velocity.x = lerp(velocity.x, 0.0, delta * SPEED_GROUND_DECCEL)
			velocity.z = lerp(velocity.z, 0.0, delta * SPEED_GROUND_DECCEL)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * SPEED_AIR)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * SPEED_AIR)
		
	# Handle head bob.
	head_bob_time += delta * velocity.length() * 1 if is_on_floor() else 0
	var pos = Vector3.ZERO
	pos.y = sin(head_bob_time * HEAD_BOB_FREQ) * HEAD_BOB_AMP
	pos.x = cos(head_bob_time * HEAD_BOB_FREQ / 2) * HEAD_BOB_AMP
	current_cam.transform.origin = pos
	
	if !play_footsteps_sfx:
		AudioManager.sfx_footsteps.audio_player.stop()
	elif !AudioManager.sfx_footsteps.audio_player.playing:
		AudioManager.play_sfx(AudioManager.sfx_footsteps, randi_range(0, 50))
	
	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPEED_SPRINT * 2.0)
	var target_fov = Game.fov + FOV_CHANGE * velocity_clamped
	current_cam.fov = lerp(current_cam.fov, target_fov, delta * SPEED_CAMERA)

	move_and_slide()
	var collision_info = get_last_slide_collision()
	if collision_info:
		var collider = collision_info.get_collider()
		var collision_normal = collision_info.get_normal()
		if collider is RigidBody3D:
			var impulse = -collision_normal * velocity.length() * PHYSICS_IMPULSE_STRENGTH
			collider.apply_central_impulse(impulse)
