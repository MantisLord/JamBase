extends Control

func _ready():
	_initialize_settings_from_config()
	
func _initialize_settings_from_config():
	var sensitivity = Config.get_config(Game.OPTIONS_GROUP_NAME, Game.MOUSE_SENSITIVITY_CONFIG_NAME)
	%SensitivityHSlider.value = sensitivity
	Game.mouse_sensitivity = sensitivity
	print("set sensitivity to %f for both game/menu" % sensitivity)

func _on_start_button_pressed():
	Game.change_scene("world")
	Menu.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_button_down():
	AudioManager.button_down_sfx.play();

func _on_button_up():
	AudioManager.button_up_sfx.play();

func _toggle_group(toggled_on, group_name):
	var members = get_tree().get_nodes_in_group(group_name)
	for member in members:
		member.visible = toggled_on;

func _on_options_button_toggled(toggled_on):
	_toggle_group(toggled_on, Game.OPTIONS_GROUP_NAME)
	if get_tree().get_first_node_in_group(Game.CONTROLS_GROUP_NAME).visible:
		_toggle_group(!toggled_on, Game.CONTROLS_GROUP_NAME)
		%ControlsButton.button_pressed = !toggled_on

func _on_controls_button_toggled(toggled_on):
	_toggle_group(toggled_on, Game.CONTROLS_GROUP_NAME)
	if get_tree().get_first_node_in_group(Game.OPTIONS_GROUP_NAME).visible:
		_toggle_group(!toggled_on, Game.OPTIONS_GROUP_NAME)
		%OptionsButton.button_pressed = !toggled_on

func _on_sensitivity_volume_h_slider_drag_ended(value_changed):
	if value_changed:
		Config.set_config(Game.OPTIONS_GROUP_NAME, Game.MOUSE_SENSITIVITY_CONFIG_NAME, %SensitivityHSlider.value)
		Game.mouse_sensitivity = %SensitivityHSlider.value

func _on_quit_button_pressed():
	get_tree().quit()
