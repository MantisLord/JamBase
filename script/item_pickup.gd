extends Node3D
class_name ItemPickup

@export var item_res: Item

func _process(_delta: float) -> void:
	%DebugLabel3D.text = str(position)
	%DebugLabel3D.text += "\r\n%s" % item_res.name

func _ready():
	%RigidBody3D.get_node(item_res.name).visible = true
	%PhysicsCollisionShape3D.shape = item_res.physics_box_shape
	%PhysicsCollisionShape3D.position = item_res.pickup_physics_box_position
