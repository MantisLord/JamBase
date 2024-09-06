extends Node3D
class_name ItemPickup

@export var item_res: Item

func _ready():
	%RigidBody3D.get_node(item_res.name).visible = true
	print("set physics box size to %s " % str(item_res.pickup_physics_box_size))
	%PhysicsCollisionShape3D.shape.size = item_res.pickup_physics_box_size
	%PhysicsCollisionShape3D.position = item_res.pickup_physics_box_position
