class_name RecordedAction
extends RefCounted

var time_seconds: float = 0.0
var relative_position: Vector2 = Vector2.ZERO
var horizontal_input: float = 0.0
var jump_pressed: bool = false
var grounded: bool = false
var velocity: Vector2 = Vector2.ZERO


func _init(
	at_time: float = 0.0,
	at_relative_position: Vector2 = Vector2.ZERO,
	at_horizontal_input: float = 0.0,
	at_jump_pressed: bool = false,
	at_grounded: bool = false,
	at_velocity: Vector2 = Vector2.ZERO
) -> void:
	time_seconds = at_time
	relative_position = at_relative_position
	horizontal_input = at_horizontal_input
	jump_pressed = at_jump_pressed
	grounded = at_grounded
	velocity = at_velocity
