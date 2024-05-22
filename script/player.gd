extends CharacterBody3D

const SPEED_RUN = 5.0
const JUMP_VELOCITY = 4.5
const MIN_ANGLE_VIEW = -40
const MAX_ANGLE_VIEW = 60

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _process(delta):
	if Input.is_action_just_pressed("menu"):
		Menu.visible = !Menu.visible
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Menu.visible else Input.MOUSE_MODE_CAPTURED
	$UI/DebugLabel.text = "FPS: %f" % Engine.get_frames_per_second()
	$UI/DebugLabel.text += "\r\nmouse_sensitivity: %f" % Game.mouse_sensitivity
	$UI/DebugLabel.text += "\r\nPlayer Position: %s" % str(position)

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		$Head.rotate_y(deg_to_rad(-event.relative.x * Game.mouse_sensitivity))
		%Cam.rotate_x(deg_to_rad(-event.relative.y * Game.mouse_sensitivity))
		%Cam.rotation.x = clamp(%Cam.rotation.x, deg_to_rad(MIN_ANGLE_VIEW), deg_to_rad(MAX_ANGLE_VIEW))

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = ($Head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED_RUN
		velocity.z = direction.z * SPEED_RUN
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED_RUN)
		velocity.z = move_toward(velocity.z, 0, SPEED_RUN)

	move_and_slide()
