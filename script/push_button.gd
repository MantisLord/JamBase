extends Interactable
class_name PushButton

@export_enum("HumanSpawner","RatSpawner","CrateSpawner","SelectStage","StartStage") var action_name: String
@export var action_display: String = "spawn humans"
@export var press_speed: float = 1.0
@export var num_spawns: int = 5
@export var sounds_press_success: Array[String] = ["button_success1", "button_success2"]
@export var sounds_press_failure: Array[String] = ["button_fail1", "button_fail2"]
@export var spawn_x_max: float = 15.0
@export var spawn_x_min: float = -15.0
@export var spawn_z_max: float = -10.0
@export var spawn_z_min: float = -15.0
@export var spawn_y_max: float = 2.5
@export var spawn_y_min: float = 1.0

var human_scene = preload("res://scene/human.tscn")
var crate_scene = preload("res://scene/crate.tscn")
var rat_scene = preload("res://scene/rat.tscn")

var color_outline_selected: Color = Color(1, 1, 0) # yellow
var color_text_selected: Color = Color(0, 0, 0) # black
var color_outline_unselected: Color = Color(0, 0, 0) # black
var color_text_unselected: Color = Color(1, 1, 1) # white

func start_press() -> void:
	if !$AnimationPlayer.is_playing():
		$AnimationPlayer.play("press", -1, press_speed)
	else:
		AudioManager.play_sfx_3d(Game.get_rand_str(sounds_press_failure), global_transform.origin)

func _get_rand_pos_in_spawn_zone() -> Vector3:
	return Vector3(randf_range(spawn_x_min, spawn_x_max), randf_range(spawn_y_min, spawn_y_max), randf_range(spawn_z_min, spawn_z_max))

func do_spawns(scene, node_name) -> void:
	for i in num_spawns:
		var instance = scene.instantiate()
		add_child(instance)
		instance.name = node_name
		instance.global_position = _get_rand_pos_in_spawn_zone()
		if action_name == "CrateSpawner":
			var random_rotation = Vector3(randf()*360,randf()*360,randf()*360)
			instance.rotation_degrees = random_rotation

func _ready() -> void:
	if action_name == "StartStage":
		_set_menu_item_colors()

func _set_menu_item_colors():
	for menu_child in get_parent().get_children():
		if menu_child is Label3D:
			if menu_child.name == "Stage%dLabel3D" % Game.hub_selected_stage_index:
				menu_child.modulate = color_text_selected
				menu_child.outline_modulate = color_outline_selected
			else:
				menu_child.modulate = color_text_unselected
				menu_child.outline_modulate = color_outline_unselected

func pressed() -> void:
	AudioManager.play_sfx_3d(Game.get_rand_str(sounds_press_success), global_transform.origin)
	match action_name:
		"HumanSpawner":
			do_spawns(human_scene, "Human")
		"RatSpawner":
			do_spawns(rat_scene, "Rat")
		"CrateSpawner":
			do_spawns(crate_scene, "Crate")
		"SelectStage":
			var num_stages = 0
			for menu_child in get_parent().get_children():
				if menu_child is Label3D:
					num_stages += 1
			Game.hub_selected_stage_index += 1
			if Game.hub_selected_stage_index == num_stages:
				Game.hub_selected_stage_index = 0
			_set_menu_item_colors()
		"StartStage":
			var selected_stage_label = get_parent().get_child(Game.hub_selected_stage_index)
			if selected_stage_label is StageLabel:
				var ret = Game.change_scene(selected_stage_label.stage)
				if ret != 0:
					AudioManager.play_sfx_3d(Game.get_rand_str(sounds_press_failure), global_transform.origin)
			else:
					AudioManager.play_sfx_3d(Game.get_rand_str(sounds_press_failure), global_transform.origin)
