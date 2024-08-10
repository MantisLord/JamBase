extends Node

const MOUSE_SENSITIVITY_CONFIG_NAME = "mouse_sensitivity"

# @onready var mouse_sensitivity = Config.get_config(OPTIONS_GROUP_NAME, MOUSE_SENSITIVITY_CONFIG_NAME)
var mouse_sensitivity
var sfx_volume
var music_volume
var master_volume

func change_scene(scene_name):
	get_tree().change_scene_to_file("scene/%s.tscn" % scene_name)
