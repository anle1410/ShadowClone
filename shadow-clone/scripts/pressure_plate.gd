class_name PressurePlate
extends Area2D

const ActorScript = preload("res://scripts/game_actor.gd")
const Visuals = preload("res://scripts/game_visuals.gd")

signal activated_changed(is_active: bool)

var is_active: bool = false
var _occupants: Dictionary[int, bool] = {}
var _glow: Polygon2D
var _light: PointLight2D
var _glow_tween: Tween


func _ready() -> void:
	_glow = $Glow
	_light = Visuals.create_light(self, Color(0.2, 0.72, 1.0, 1.0), 0.1, 0.48)
	_light.position = Vector2(0.0, -5.0)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	var actor: ActorScript = body as ActorScript
	if actor == null:
		return
	_occupants[actor.get_instance_id()] = true
	if actor.is_echo:
		actor.set_echo_emphasis(true)
	_set_active(not _occupants.is_empty())


func _on_body_exited(body: Node2D) -> void:
	var actor: ActorScript = body as ActorScript
	if actor == null:
		return
	_forget_actor(actor)


func forget_actor(body: Node2D) -> void:
	var actor: ActorScript = body as ActorScript
	if actor == null:
		return
	_forget_actor(actor)


func reset_state() -> void:
	_occupants.clear()
	_set_active(false)


func _forget_actor(actor: ActorScript) -> void:
	_occupants.erase(actor.get_instance_id())
	if actor.is_echo:
		actor.set_echo_emphasis(false)
	_set_active(not _occupants.is_empty())


func _set_active(value: bool) -> void:
	if is_active == value:
		return
	is_active = value
	_animate_visual(value)
	activated_changed.emit(is_active)


func set_visual_active(value: bool) -> void:
	_animate_visual(value)


func _animate_visual(value: bool) -> void:
	if _glow_tween != null and _glow_tween.is_running():
		_glow_tween.kill()
	_glow_tween = create_tween()
	_glow_tween.set_parallel(true)
	_glow_tween.tween_property(
		_glow,
		"color",
		Color(0.21, 0.86, 1.0, 0.7) if value else Color(0.16, 0.65, 0.88, 0.18),
		0.18
	)
	_glow_tween.tween_property(_light, "energy", 0.9 if value else 0.1, 0.18)
