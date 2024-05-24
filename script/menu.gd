extends Control

var remapping_control = false
var remap_action_name
var remap_control_button

var last_input_event : InputEvent

const controls_label_default = "click a button to remap action"
const controls_label_remapping = ""

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

func _on_forward_button_pressed():
	_start_remap_control(%ForwardButton, Game.ACTION_FORWARD)
	
func _unhandled_input(event):
	if !visible:
		return
	if event is InputEventKey and remapping_control:
		var input_event_text = OS.get_keycode_string(event.get_physical_keycode_with_modifiers())
		if input_event_text.is_empty():
			return
		last_input_event = event
		$MainVBoxContainer/TitleMarginContainer/DebugLabel.text += "\r\nlast_input_event: " + input_event_text
		remapping_control = false
		remap_control_button.text = input_event_text
		#InputMap.action_erase_event(remap_action_name, )
		_toggle_buttons_in_group(Game.OPTIONS_GROUP_NAME, false)

func _toggle_buttons_in_group(group_name, disabled):
	for member in get_tree().get_nodes_in_group(group_name):
		if member is Button:
			member.disabled = disabled		
		
		
func _start_remap_control(control_button, action_name):
	_toggle_buttons_in_group(Game.OPTIONS_GROUP_NAME, true)
	remapping_control = true
	remap_action_name = action_name
	remap_control_button = control_button
	control_button.text = "..."
	$MainVBoxContainer/TitleMarginContainer/DebugLabel.text = "remap_action_name: " + remap_action_name
