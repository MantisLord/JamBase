extends Control

var remapping_control = false
var remap_action_name
var remap_control_button

func _ready():
	_initialize_settings_from_config()
	AudioManager.play_music(AudioManager.music_hurdy)
	var control_buttons = get_tree().get_nodes_in_group("control_buttons")
	for button in control_buttons:
		button.connect("pressed", Callable(self, "_on_control_button_remap_pressed").bind(button))
	if OS.get_name() == "Web":
		%QuitButton.visible = false

func _initialize_settings_from_config():
	var sensitivity = Config.get_config("options", Game.MOUSE_SENSITIVITY_CONFIG_NAME, 0.05)
	%SensitivityHSlider.value = sensitivity
	Game.mouse_sensitivity = sensitivity
	
	var master_volume = Config.get_config("options", Game.MASTER_VOLUME_CONFIG_NAME, 1.0)
	%MasterVolumeHSlider.value = master_volume * 100
	Game.master_volume = master_volume
	
	var sfx_volume = Config.get_config("options", Game.SFX_VOLUME_CONFIG_NAME, 1.0)
	%SFXVolumeHSlider.value = sfx_volume * 100
	Game.sfx_volume = sfx_volume
	
	var music_volume = Config.get_config("options", Game.MUSIC_VOLUME_CONFIG_NAME, 1.0)
	%MusicVolumeHSlider.value = music_volume * 100
	Game.music_volume = music_volume
	
	var fullscreen = Config.get_config("options", Game.FULLSCREEN_CONFIG_NAME, false)
	%FullscreenCheckBox.button_pressed = fullscreen
	Game.toggle_fullscreen(fullscreen)
	
	var debug_mode = Config.get_config("options", Game.DEBUG_MODE_CONFIG_NAME, false)
	%DebugModeCheckBox.button_pressed = debug_mode
	Game.debug_mode = debug_mode
	
	var cam_mode = Config.get_config("options", Game.CAM_MODE_CONFIG_NAME, 0)
	%CamModeOptionButton.selected = cam_mode
	Game.cam_mode = cam_mode

func _on_start_button_pressed():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Game.change_scene("world")

func _on_button_down():
	AudioManager.play_sfx(AudioManager.sfx_btn_down)

func _on_button_up():
	AudioManager.play_sfx(AudioManager.sfx_btn_up)

func _toggle_group(toggled_on, group_name):
	var members = get_tree().get_nodes_in_group(group_name)
	for member in members:
		member.visible = toggled_on;

func _on_options_button_toggled(toggled_on):
	_toggle_group(toggled_on, "options")
	if get_tree().get_first_node_in_group("controls").visible:
		_toggle_group(!toggled_on, "controls")
		%ControlsButton.button_pressed = !toggled_on

func _on_controls_button_toggled(toggled_on):
	_toggle_group(toggled_on, "controls")
	if get_tree().get_first_node_in_group("options").visible:
		_toggle_group(!toggled_on, "options")
		%OptionsButton.button_pressed = !toggled_on

func _on_sensitivity_volume_h_slider_drag_ended(value_changed):
	if value_changed:
		Config.set_config("options", Game.MOUSE_SENSITIVITY_CONFIG_NAME, %SensitivityHSlider.value)
		Game.mouse_sensitivity = %SensitivityHSlider.value

func _on_quit_button_pressed():
	get_tree().quit()

func _on_control_button_remap_pressed(button: Button):
	_toggle_buttons_in_group("control_buttons", true)
	remapping_control = true
	remap_action_name = button.name.replace("Button","").to_lower()
	remap_control_button = button
	remap_control_button.text = "..."

func _input(event):
	if !visible:
		return
	if remapping_control:
		if (event is InputEventMouseButton or event is InputEventKey) and event.pressed:
			remap_control_button.text = get_key_name_from_event(event)
			InputMap.action_erase_events(remap_action_name)
			InputMap.action_add_event(remap_action_name, event)
			remapping_control = false
			_toggle_buttons_in_group("control_buttons", false)

func _toggle_buttons_in_group(group_name, disabled):
	for member in get_tree().get_nodes_in_group(group_name):
		if member is Button:
			member.disabled = disabled

func _on_fullscreen_check_box_toggled(toggled_on):
	Config.set_config("options", Game.FULLSCREEN_CONFIG_NAME, toggled_on)
	Game.toggle_fullscreen(toggled_on)

func _on_debug_mode_check_box_toggled(toggled_on: bool) -> void:
	Config.set_config("options", Game.DEBUG_MODE_CONFIG_NAME, toggled_on)
	Game.debug_mode = toggled_on

func _on_cam_mode_option_button_item_selected(index: int) -> void:
	Config.set_config("options", Game.CAM_MODE_CONFIG_NAME, index)
	Game.cam_mode = index

func _on_master_volume_h_slider_value_changed(value):
	Config.set_config("options", Game.MASTER_VOLUME_CONFIG_NAME, value / 100)
	Game.master_volume = value / 100
	AudioManager.adjust_playing_audio()

func _on_music_volume_h_slider_value_changed(value):
	Config.set_config("options", Game.MUSIC_VOLUME_CONFIG_NAME, value / 100)
	Game.music_volume = value / 100
	AudioManager.adjust_playing_audio()

func _on_sfx_volume_h_slider_value_changed(value):
	Config.set_config("options", Game.SFX_VOLUME_CONFIG_NAME, value / 100)
	Game.sfx_volume = value / 100
	AudioManager.adjust_playing_audio()

func get_mouse_button_string(button_index: int) -> String:
	match button_index:
		MOUSE_BUTTON_LEFT:
			return "LMouse"
		MOUSE_BUTTON_RIGHT:
			return "RMouse"
		MOUSE_BUTTON_MIDDLE:
			return "MidMouse"
		MOUSE_BUTTON_WHEEL_UP:
			return "WheelUp"
		MOUSE_BUTTON_WHEEL_DOWN:
			return "WheelDown"
		MOUSE_BUTTON_XBUTTON1:
			return "Mouse4"
		MOUSE_BUTTON_XBUTTON2:
			return "Mouse5"
		_:
			return "Mouse%d" % button_index

func get_key_name_from_event(event) -> String:
	if event is InputEventKey:
		return OS.get_keycode_string(event.get_physical_keycode_with_modifiers())
	elif event is InputEventMouseButton:
		return get_mouse_button_string(event.button_index)
	return ""

func get_key_name_from_action(action_name) -> String:
	var input_events = InputMap.action_get_events(action_name)
	var key_name = ""
	for event in input_events:
		if event is InputEventKey:
			key_name = get_key_name_from_event(event)
	return key_name
