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

func _ready():
	%Menu.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(_delta):
	if Input.is_action_just_pressed("menu"):
		%Menu.visible = !%Menu.visible
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if %Menu.visible else Input.MOUSE_MODE_CAPTURED
		
	%DebugLabel.text = "FPS: %f" % Engine.get_frames_per_second()
	%DebugLabel.text += "\r\nmouse_sensitivity: %f" % Game.mouse_sensitivity
	%DebugLabel.text += "\r\nPlayer Position: %s" % str(position)
	
	if %InteractRayCast3D.is_colliding():
		var collider = %InteractRayCast3D.get_collider()
		if collider is Interactable:		
			%InteractLabel.text = "Press %s to interact with %s." % %Menu.get_key_name_from_action("interact") % collider.name
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
		AudioManager.play_sfx(AudioManager.jump_sfx, 0.05)
		play_footsteps_sfx = false

	# Get the input direction.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = ($Head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Handle move speed.
	if Input.is_action_pressed("crouch"):
		$Head.position.y = lerp($Head.position.y, CROUCH_DEPTH, delta * SPEED_HEAD)
		speed = SPEED_CROUCH
		AudioManager.footsteps_sfx.pitch_scale = 0.6
		%CrouchCollisionShape3D.disabled = false;
		%StandCollisionShape3D.disabled = true;
	elif !%HeadCollisionRayCast3D.is_colliding():
		%CrouchCollisionShape3D.disabled = true;
		%StandCollisionShape3D.disabled = false;
		$Head.position.y = lerp($Head.position.y, 0.5, delta * SPEED_HEAD)
		if Input.is_action_pressed("sprint"):
			speed = SPEED_SPRINT
			AudioManager.footsteps_sfx.pitch_scale = 1.6
		else:
			speed = SPEED_RUN
			AudioManager.footsteps_sfx.pitch_scale = 1.0

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
		AudioManager.footsteps_sfx.stop()
	elif !AudioManager.footsteps_sfx.playing:
		AudioManager.play_sfx(AudioManager.footsteps_sfx, 0.1, randi_range(0, 50))
	
	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPEED_SPRINT * 2.0)
	var target_fov = FOV_BASE + FOV_CHANGE * velocity_clamped
	%Cam.fov = lerp(%Cam.fov, target_fov, delta * SPEED_CAMERA)

	move_and_slide()
