extends Node

const MOUSE_SENSITIVITY_CONFIG_NAME = "mouse_sensitivity"
const MASTER_VOLUME_CONFIG_NAME = "master_volume"
const MUSIC_VOLUME_CONFIG_NAME = "music_volume"
const SFX_VOLUME_CONFIG_NAME = "sfx_volume"
const FULLSCREEN_CONFIG_NAME = "fullscreen"
const DEBUG_MODE_CONFIG_NAME = "debug_mode"
const CAM_MODE_CONFIG_NAME = "cam_mode"
const VSYNC_MODE_CONFIG_NAME = "vsync_mode"

var mouse_sensitivity
var sfx_volume
var music_volume
var master_volume
var debug_mode
var cam_mode

func get_rand_str(string_array: Array[String]) -> String:
	return string_array[int(randf() * string_array.size())]

func change_scene(scene_name):
	get_tree().change_scene_to_file("scene/%s.tscn" % scene_name)

func toggle_fullscreen(toggled_on):
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

func toggle_vsync(toggled_on):
	if toggled_on:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func handle_physics_collision(raycast, attacker, collider, velocity, weapon):
	var impulse = -raycast.get_collision_normal() * velocity.length() *  weapon.physics_impulse_strength
	var should_log = false
	if collider is RigidBody3D:
		collider.apply_impulse(impulse, raycast.get_collision_point())
		should_log = true
	if collider is BodyPart:
		var topmost_parent = collider
		while topmost_parent.get_parent() != null:
			topmost_parent = topmost_parent.get_parent()
			if topmost_parent is PhysicalBoneSimulator3D:
				if topmost_parent.is_simulating_physics():
					collider.apply_impulse(impulse, raycast.get_collision_point())
					should_log = true
			if topmost_parent is Unit:
				var final_dmg = randf_range(weapon.damage_min, weapon.damage_max) * collider.damage_multiplier
				topmost_parent.hit(final_dmg, attacker, collider.part_name)
	if should_log:
		log_out("Programmed collision occurred, impulse %s [%s's %s -> %s]" % [impulse, attacker.name, weapon.name, collider.name])

func log_out(text) -> void:
	if Game.debug_mode:
		if get_tree().current_scene != null:
			var player = get_tree().current_scene.get_node_or_null("Player")
			if player != null:
				var scroll_container = player.get_node("UI/DebugLogMarginContainer/DebugLogPanelContainer/DebugLogInnerMarginContainer/DebugLogScrollContainer")
				scroll_container.get_node("DebugLogLabel").text += "\r\n%s" % text
				await get_tree().process_frame
				scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value
	print(text)
