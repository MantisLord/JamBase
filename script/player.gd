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
const MIN_ANGLE_VIEW = -40
const MAX_ANGLE_VIEW = 60
const CROUCH_DEPTH = -0.5
const HEAD_BOB_FREQ = 2.4
const HEAD_BOB_AMP = 0.08
const FOV_BASE = 75.0
const FOV_CHANGE = 1.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var play_footsteps_sfx = false
var speed = 0.0
var head_bob_time = 0.0

var inventory = []
var equipped_item_index = -1
var equipped_item_instance
var item_panel = preload("res://scene/item_panel.tscn")
var is_animating = false
var item_pickup = preload("res://scene/item_pickup.tscn")

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
	var dropping_index = equipped_item_index
	await _unequip_item()
	var pickup = item_pickup.instantiate()
	pickup.item_res = item_res
	pickup.position = position
	get_tree().root.add_child(pickup)
	inventory.remove_at(dropping_index)
	var panel = %InventoryHBoxContainer.get_child(equipped_item_index)
	%InventoryHBoxContainer.remove_child(panel)
	panel.queue_free()
	_log("dropped %s " % item_res.name)

func _unequip_item() -> void:
	if is_animating:
		return
	if equipped_item_index != -1:
		_log("unequipped %s" % inventory[equipped_item_index].name)
		AudioManager.play_sfx_by_name(inventory[equipped_item_index].equip_sound)
		%AnimationPlayer.play("lower")
		is_animating = true
		await %AnimationPlayer.animation_finished
		is_animating = false
		for child in %EquippedItemNode3D.get_children():
			if child.name == "weapon_rot_tracker":
				%EquippedItemNode3D.remove_child(child)
		equipped_item_instance.queue_free()
		equipped_item_instance = null
		equipped_item_index = -1

func _equip_item(new_index) -> void:
	if is_animating:
		return
	if equipped_item_index != -1:
		await _unequip_item()
	var item_res = inventory[new_index]
	var item_scene = load(item_res.scene_path)
	equipped_item_instance = item_scene.instantiate()
	#equipped_item_instance.scale = item_res.display_scale
	var rotation_parent = Node3D.new()
	rotation_parent.name = "weapon_rot_tracker"
	%EquippedItemNode3D.add_child(rotation_parent)
	rotation_parent.rotation_degrees.y = %Head.rotation.y + item_res.equip_rotation_y_offset
	equipped_item_instance.position = item_res.equip_position
	rotation_parent.add_child(equipped_item_instance)
	%AnimationPlayer.play("raise")
	is_animating = true
	AudioManager.play_sfx_by_name(inventory[equipped_item_index].equip_sound)
	await %AnimationPlayer.animation_finished
	is_animating = false
	equipped_item_index = new_index
	_log("equipped %s" % inventory[equipped_item_index].name)

func _shoot(weapon):
	if weapon.left_in_clip > 0:
		equipped_item_instance.get_node("AnimationPlayer").play("fire")
		AudioManager.play_sfx_by_name(weapon.shoot_sound)
		weapon.left_in_clip -= 1
	else:
		AudioManager.play_sfx_by_name(weapon.clip_empty_sound)

func _reload(weapon):
	if weapon.total_ammo > 0 && weapon.left_in_clip < weapon.max_clip_size:
		AudioManager.play_sfx_by_name(weapon.reload_sound)
		var amount = min(weapon.total_ammo, weapon.max_clip_size)
		weapon.total_ammo -= amount - weapon.left_in_clip
		weapon.left_in_clip = min(weapon.total_ammo, weapon.max_clip_size)
		
func _ready():
	%Menu.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(_delta):
	if Input.is_action_just_pressed("menu"):
		%Menu.visible = !%Menu.visible
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if %Menu.visible else Input.MOUSE_MODE_CAPTURED
	
	for n in inventory.size():
		if Input.is_action_just_pressed("selectitem%d" % (n + 1)) && !is_animating:
			_log("detected player selected item index %d" % n)
			if n == equipped_item_index:
				_unequip_item()
			else:
				_equip_item(n)
			
	%DebugLabel.text = "FPS: %f" % Engine.get_frames_per_second()
	%DebugLabel.text += "\r\nmouse_sensitivity: %f" % Game.mouse_sensitivity
	%DebugLabel.text += "\r\nPlayer Position: %s" % str(position)
	if equipped_item_index != -1:
		var equipped_item_res = inventory[equipped_item_index];
		%DebugLabel.text += "\r\nEquipped %s (%d)" % [equipped_item_res.name, equipped_item_index]
		if !%Menu.visible && Input.is_action_just_pressed("drop"):
			_drop_item(equipped_item_res)
		if equipped_item_res is Weapon:
			%DebugLabel.text += "\r\nCurrent Clip (%d/%d)" % [equipped_item_res.left_in_clip, equipped_item_res.max_clip_size]
			%DebugLabel.text += "\r\nAmmo: %d" % equipped_item_res.total_ammo
			if %AnimationPlayer.animation_finished && !%Menu.visible:
				if Input.is_action_just_pressed("shoot"):
					_shoot(equipped_item_res)
				if Input.is_action_just_pressed("reload"):
					_reload(equipped_item_res)
	else:
		%DebugLabel.text += "\r\nNothing equipped."
	
	if %InteractRayCast3D.is_colliding():
		var collider = %InteractRayCast3D.get_collider().get_parent()
		if collider is ItemPickup:
			%InteractLabel.text = "Press %s to pick up %s." % [%Menu.get_key_name_from_action("interact"), collider.item_res.name]
			if Input.is_action_just_pressed("interact"):
				_pick_up_item(collider.item_res)
				collider.queue_free()
	else:
		%InteractLabel.text = ""

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
