extends Control

var remapping_control = false
var remap_action_name
var remap_control_button

var last_input_event : InputEvent

const controls_label_default = "click a button to remap action"
const controls_label_remapping = ""

func _ready():
	_initialize_settings_from_config()
	var control_buttons = get_tree().get_nodes_in_group("control_buttons")
	for button in control_buttons:
		button.connect("pressed", Callable(self, "_on_control_button_remap_pressed").bind(button))

func _initialize_settings_from_config():
	var sensitivity = Config.get_config("options", Game.MOUSE_SENSITIVITY_CONFIG_NAME)
	%SensitivityHSlider.value = sensitivity
	Game.mouse_sensitivity = sensitivity
	print("set sensitivity to %f for both game/menu" % sensitivity)

func _on_start_button_pressed():
	Game.change_scene("world")
	Menu.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_button_down():
	AudioManager.play_sfx(AudioManager.button_down_sfx, 1.5)

func _on_button_up():
	AudioManager.play_sfx(AudioManager.button_up_sfx, 1.5)

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
		Config.set_config(Game.OPTIONS_GROUP_NAME, Game.MOUSE_SENSITIVITY_CONFIG_NAME, %SensitivityHSlider.value)
		Game.mouse_sensitivity = %SensitivityHSlider.value

func _on_quit_button_pressed():
	get_tree().quit()

func _on_control_button_remap_pressed(button: Button):
	_toggle_buttons_in_group("control_buttons", true)
	remapping_control = true
	remap_action_name = button.name.replace("Button","").to_lower()
	remap_control_button = button
	remap_control_button.text = "..."
	%DebugLabel.text = "remap_action_name: " + remap_action_name

func _unhandled_input(event):
	if !visible:
		return
	if event is InputEventKey and remapping_control:
		var input_event_text = OS.get_keycode_string(event.get_physical_keycode_with_modifiers())
		if input_event_text.is_empty():
			return
		last_input_event = event
		%DebugLabel.text += "\r\nlast_input_event: " + input_event_text
		remapping_control = false
		remap_control_button.text = input_event_text
		InputMap.action_erase_events(remap_action_name)
		InputMap.action_add_event(remap_action_name, event)
		_toggle_buttons_in_group("control_buttons", false)

func _toggle_buttons_in_group(group_name, disabled):
	for member in get_tree().get_nodes_in_group(group_name):
		if member is Button:
			member.disabled = disabled

func _on_fullscreen_check_box_toggled(toggled_on):
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2(800, 600))
		var primary_screen_index = DisplayServer.get_primary_screen()
		var screen_position = DisplayServer.screen_get_position(primary_screen_index)
		var screen_size = DisplayServer.screen_get_size(primary_screen_index)
		var window_size = DisplayServer.window_get_size()
		var new_position = screen_position + (screen_size - window_size) / 2
		DisplayServer.window_set_position(new_position)

func _on_master_volume_h_slider_value_changed(value):
	AudioManager.set_master_volume(value / 100)

func _on_music_volume_h_slider_value_changed(value):
	AudioManager.set_music_volume(value / 100)

func _on_sfx_volume_h_slider_value_changed(value):
	AudioManager.set_sfx_volume(value / 100)
