extends Area3D
class_name InteractButton

@export_enum("HumanSpawner","RatSpawner","CrateSpawner") var action_name: String
@export var action_display: String = "spawn humans"
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

func start_press() -> void:
	if !$AnimationPlayer.is_playing():
		$AnimationPlayer.play("press")
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

func pressed() -> void:
	AudioManager.play_sfx_3d(Game.get_rand_str(sounds_press_success), global_transform.origin)
	match action_name:
		"HumanSpawner":
			do_spawns(human_scene, "Human")
		"RatSpawner":
			do_spawns(rat_scene, "Rat")
		"CrateSpawner":
			do_spawns(crate_scene, "Crate")
