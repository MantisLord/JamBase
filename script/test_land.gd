extends Node3D

func _process(_delta: float) -> void:
	var visual = ImmediateMesh.new()
	visual.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	visual.surface_add_vertex(%VisualNode3D.global_position)
	visual.surface_add_vertex(%VisualNode3D2.global_position)
	visual.surface_add_vertex($Player.global_position)
	visual.surface_end()
	var instance = MeshInstance3D.new()
	instance.mesh = visual
	add_child(instance)
