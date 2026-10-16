class_name ExitDoor
extends Node2D

const ActorScript = preload("res://scripts/game_actor.gd")
const Visuals = preload("res://scripts/game_visuals.gd")

signal exit_reached

var is_open: bool = false

@onready var _solid_shape: CollisionShape2D = $Solid/CollisionShape2D
@onready var _door_polygon: Polygon2D = $DoorVisual
@onready var _exit_sensor: Area2D = $ExitSensor
var _rune: Polygon2D
var _door_light: PointLight2D
var _door_tween: Tween


func _ready() -> void:
	_exit_sensor.body_entered.connect(_on_exit_sensor_body_entered)
	_rune = $DoorRune
	_door_light = Visuals.create_light(self, Color(0.18, 0.76, 1.0, 1.0), 0.12, 0.72)
	_door_light.position = Vector2(0.0, -2.0)
	_set_open(false)


func set_open(value: bool) -> void:
	_set_open(value)


func _set_open(value: bool) -> void:
	is_open = value
	_solid_shape.set_deferred("disabled", is_open)
	if _door_tween != null and _door_tween.is_running():
		_door_tween.kill()
	_door_tween = create_tween()
	_door_tween.set_parallel(true)
	_door_tween.tween_property(_door_polygon, "modulate:a", 0.18 if is_open else 1.0, 0.22)
	_door_tween.tween_property(
		_door_polygon,
		"scale",
		Vector2(0.18, 1.0) if is_open else Vector2.ONE,
		0.22
	)
	_door_tween.tween_property(_rune, "color:a", 0.92 if is_open else 0.72, 0.22)
	_door_tween.tween_property(_door_light, "energy", 0.82 if is_open else 0.12, 0.22)
	if is_open:
		call_deferred("_check_sensor_occupants")


func _check_sensor_occupants() -> void:
	if not is_open:
		return
	for body: Node2D in _exit_sensor.get_overlapping_bodies():
		_on_exit_sensor_body_entered(body)


func _on_exit_sensor_body_entered(body: Node2D) -> void:
	var actor: ActorScript = body as ActorScript
	if is_open and actor != null and not actor.is_echo:
		exit_reached.emit()
