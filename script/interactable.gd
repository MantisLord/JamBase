extends Node3D
class_name Interactable

@export var highlight_on_focus: bool = true

var highlight_material = preload("res://resource/interactable_highlight.tres")

func focus():
	if highlight_on_focus:
		for mesh in Game.get_all_mesh_instance3ds(self):
			mesh.material_overlay = highlight_material

func unfocus():
	if highlight_on_focus:
		for mesh in Game.get_all_mesh_instance3ds(self):
			mesh.material_overlay = null
