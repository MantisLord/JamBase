extends Node3D

func _ready() -> void:
	$BodyAnimationPlayer.play("Robot Walk Legs")
	$BodyAnimationPlayer2.play("Robot Walk Arms")
