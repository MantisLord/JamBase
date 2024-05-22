extends Node

const CONTROLS_GROUP_NAME = "controls";
const OPTIONS_GROUP_NAME = "options";
const MOUSE_SENSITIVITY_CONFIG_NAME = "mouse_sensitivity";

# @onready var mouse_sensitivity = Config.get_config(OPTIONS_GROUP_NAME, MOUSE_SENSITIVITY_CONFIG_NAME)
var mouse_sensitivity

func change_scene(scene_name):
	get_tree().change_scene_to_file("scene/%s.tscn" % scene_name)
