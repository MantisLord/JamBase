extends Node3D
class_name ItemPickup

@export var item_res: Item

func _ready():
	var scene = load(item_res.scene_path)
	var instance = scene.instantiate()
	instance.scale = item_res.display_scale
	instance.rotation = item_res.pickup_rotation
	%CollisionShape3D.shape.size = item_res.pickup_collider_size
	add_child(instance)
