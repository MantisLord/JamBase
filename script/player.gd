extends CharacterBody3D

const SPEED_RUN = 5.0
const SPEED_SPRINT = 8.0
const SPEED_CROUCH = 3.0
const SPEED_AIR = 0.5
const SPEED_GROUND_ACCEL = 10.0
const SPEED_GROUND_DECCEL = 7.0
const SPEED_HEAD = 10.0
const SPEED_CAMERA = 8.0
const JUMP_VELOCITY = 4.5
const MIN_ANGLE_VIEW = -60
const MAX_ANGLE_VIEW = 60
const CROUCH_DEPTH = -0.5
const HEAD_BOB_FREQ = 2.4
const HEAD_BOB_AMP = 0.08
const FOV_BASE = 75.0
const FOV_CHANGE = 1.5
const PHYSICS_IMPULSE_STRENGTH: float = 0.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var play_footsteps_sfx = false
var speed = 0.0
var head_bob_time = 0.0

var inventory = []
var equipped_item_index = -1
var equipped_item_instance
var item_panel = preload("res://scene/item_panel.tscn")
var item_pickup = preload("res://scene/item_pickup.tscn")

var bullet = preload("res://scene/bullet.tscn")

func _pick_up_item(item_res) -> void:
	if !%InventoryPanelContainer.visible:
		%InventoryPanelContainer.visible = true
	inventory.append(item_res)
	var panel = item_panel.instantiate()
	panel.get_node("TextureRect").texture = load(item_res.icon)
	var action_name = "selectitem%d" % int(inventory.size())
	var key_name = %Menu.get_key_name_from_action(action_name)
	_log("got key name %s for action name %s" % [key_name, action_name])
	panel.get_node("BindLabel").text = key_name
	%InventoryHBoxContainer.add_child(panel)
	_log("picked up %s" % item_res.name)
	AudioManager.play_sfx_by_name(item_res.pickup_sound)
	if equipped_item_index == -1:
		_log("auto-equipping %s" % item_res.name)
		_equip_item(inventory.size() - 1)

func _log(text) -> void:
	%DevLogLabel.text += "\r\n%s" % text
	await get_tree().process_frame
	%ScrollContainer.scroll_vertical = %ScrollContainer.get_v_scroll_bar().max_value
	print(text)

func _drop_item(item_res) -> void:
	if %AnimationPlayer.is_playing():
		return
	var dropping_index = equipped_item_index
	await _unequip_item()
	var pickup = item_pickup.instantiate()
	pickup.item_res = item_res
	get_tree().root.add_child(pickup)
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
	_log("dropped %s " % item_res.name)

func _unequip_item() -> void:
	if %AnimationPlayer.is_playing():
		return
	if equipped_item_index != -1:
		_log("unequipped %s" % inventory[equipped_item_index].name)
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
	rotation_parent.rotation_degrees.y = %Head.rotation.y + item_res.equip_rotation_y_offset
	equipped_item_instance.position = item_res.equip_position
	rotation_parent.add_child(equipped_item_instance)
	%AnimationPlayer.play("raise")
	AudioManager.play_sfx_by_name(inventory[new_index].equip_sound)
	await %AnimationPlayer.animation_finished
	equipped_item_index = new_index
	_log("equipped %s" % inventory[equipped_item_index].name)

func _use(item):
	if item is Weapon:
		_shoot(item)
	else:
		var item_anim_player = equipped_item_instance.get_node("AnimationPlayer")
		if !item_anim_player.is_playing():
			item_anim_player.play("use")
			if item.name == "Key":
				await get_tree().create_timer(1.0).timeout
				if %InteractRayCast3D.is_colliding():
					var collider = %InteractRayCast3D.get_collider().get_parent()
					if collider is Door:
						collider.locked = !collider.locked
						AudioManager.play_sfx_by_name(item.use_sound)
						var action_word = "unlock"
						if collider.locked:
							action_word = "lock"
						_log("Used key to %s door." % action_word)
	
func _shoot(weapon):
	if weapon.left_in_clip > 0:
		equipped_item_instance.get_node("AnimationPlayer").play("fire")
		AudioManager.play_sfx_by_name(weapon.shoot_sound)
		weapon.left_in_clip -= 1
		
		var bullet_instance = bullet.instantiate()
		bullet_instance.position = equipped_item_instance.get_node("BarrelNode3D").global_position
		get_tree().root.add_child(bullet_instance)
		if %AimRayCast3D.is_colliding():
			_log("bullet targeting %s shot" % %AimRayCast3D.get_collider().name)
			bullet_instance.set_velocity(%AimRayCast3D.get_collision_point())
		else:
			bullet_instance.set_velocity(%AimRayEndNode3D.global_position)
	else:
		AudioManager.play_sfx_by_name(weapon.clip_empty_sound)

func _reload(weapon):
	if weapon.left_in_clip == weapon.max_clip_size:
		return
	var needed = weapon.max_clip_size - weapon.left_in_clip
	var reload_amount = min(needed, weapon.total_ammo)
	if reload_amount > 0:
		AudioManager.play_sfx_by_name(weapon.reload_sound)
	weapon.left_in_clip += reload_amount
	weapon.total_ammo -= reload_amount

func _ready():
	%Menu.visible = false
	%Menu.get_node("%TitleMarginContainer").visible = false
	%Menu.get_node("%MainPanelContainer").size_flags_vertical = Control.SIZE_SHRINK_CENTER + Control.SIZE_EXPAND
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(_delta):
	if Input.is_action_just_pressed("menu"):
		%Menu.visible = !%Menu.visible
		%CrosshairTextureRect.visible = !%Menu.visible
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if %Menu.visible else Input.MOUSE_MODE_CAPTURED
	
	if !%AnimationPlayer.is_playing():
		for n in inventory.size():
			if Input.is_action_just_pressed("selectitem%d" % (n + 1)):
				_log("detected player selected item index %d" % n)
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
			
	%DebugLabel.text = "FPS: %f" % Engine.get_frames_per_second()
	%DebugLabel.text += "\r\nmouse_sensitivity: %f" % Game.mouse_sensitivity
	%DebugLabel.text += "\r\nPlayer Position: %s" % str(position)
	if equipped_item_index != -1:
		var equipped_item_res = inventory[equipped_item_index];
		%DebugLabel.text += "\r\nEquipped %s (%d)" % [equipped_item_res.name, equipped_item_index]
		if equipped_item_res is Weapon:
			%DebugLabel.text += "\r\nCurrent Clip (%d/%d)" % [equipped_item_res.left_in_clip, equipped_item_res.max_clip_size]
			%DebugLabel.text += "\r\nAmmo: %d" % equipped_item_res.total_ammo
		if !%Menu.visible && Input.is_action_just_pressed("drop"):
			_drop_item(equipped_item_res)
		if !%AnimationPlayer.is_playing() && !%Menu.visible:
			if Input.is_action_just_pressed("useitem"):
				_use(equipped_item_res)
			if equipped_item_res is Weapon && Input.is_action_just_pressed("reload"):
				_reload(equipped_item_res)
	else:
		%DebugLabel.text += "\r\nNothing equipped."
	
	if !%Menu.visible:
		if %InteractRayCast3D.is_colliding():
			var collider = %InteractRayCast3D.get_collider().get_parent()
			if collider is ItemPickup:
				%InteractLabel.text = "Press %s to pick up %s." % [%Menu.get_key_name_from_action("interact"), collider.item_res.name]
				%CrosshairTextureRect.visible = false
				if Input.is_action_just_pressed("interact"):
					_pick_up_item(collider.item_res)
					collider.queue_free()
			elif collider is Door:
				if collider.locked:
					%CrosshairTextureRect.visible = false
					%InteractLabel.text = "Locked."
				else:
					%CrosshairTextureRect.visible = true
					%InteractLabel.text = ""
		else:
			%InteractLabel.text = ""
			%CrosshairTextureRect.visible = true

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		$Head.rotate_y(deg_to_rad(-event.relative.x * Game.mouse_sensitivity))
		%Cam.rotate_x(deg_to_rad(-event.relative.y * Game.mouse_sensitivity))
		%Cam.rotation.x = clamp(%Cam.rotation.x, deg_to_rad(MIN_ANGLE_VIEW), deg_to_rad(MAX_ANGLE_VIEW))

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		play_footsteps_sfx = false

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		AudioManager.play_sfx(AudioManager.sfx_jump)
		play_footsteps_sfx = false

	# Get the input direction.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = ($Head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Handle move speed.
	if Input.is_action_pressed("crouch"):
		$Head.position.y = lerp($Head.position.y, CROUCH_DEPTH, delta * SPEED_HEAD)
		speed = SPEED_CROUCH
		AudioManager.sfx_footsteps.audio_player.pitch_scale = 0.6
		%CrouchCollisionShape3D.disabled = false;
		%StandCollisionShape3D.disabled = true;
	elif !%HeadCollisionRayCast3D.is_colliding():
		%CrouchCollisionShape3D.disabled = true;
		%StandCollisionShape3D.disabled = false;
		$Head.position.y = lerp($Head.position.y, 0.5, delta * SPEED_HEAD)
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
	%Cam.transform.origin = pos
	
	if !play_footsteps_sfx:
		AudioManager.sfx_footsteps.audio_player.stop()
	elif !AudioManager.sfx_footsteps.audio_player.playing:
		AudioManager.play_sfx(AudioManager.sfx_footsteps, randi_range(0, 50))
	
	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPEED_SPRINT * 2.0)
	var target_fov = FOV_BASE + FOV_CHANGE * velocity_clamped
	%Cam.fov = lerp(%Cam.fov, target_fov, delta * SPEED_CAMERA)

	move_and_slide()
	var collision_info = get_last_slide_collision()
	if collision_info:
		var collider = collision_info.get_collider()
		var collision_normal = collision_info.get_normal()
		if collider is RigidBody3D:
			var impulse = -collision_normal * velocity.length() * PHYSICS_IMPULSE_STRENGTH
			collider.apply_central_impulse(impulse)
