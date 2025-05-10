extends Node3D

func _spawn_new_line(origin, dest):
	var visual = ImmediateMesh.new()
	visual.surface_begin(Mesh.PRIMITIVE_LINES)
	visual.surface_add_vertex(origin)
	visual.surface_add_vertex(dest)
	visual.surface_end()
	var instance = MeshInstance3D.new()
	instance.mesh = visual
	add_child(instance)
	
func _process(_delta: float) -> void:
	_spawn_new_line(%VisualNode3D.global_position, $Player.global_position)
	_spawn_new_line(%VisualNode3D2.global_position, $Player.global_position)
