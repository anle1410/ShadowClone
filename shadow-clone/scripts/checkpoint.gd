class_name GameCheckpoint
extends Area2D

const ActorScript = preload("res://scripts/game_actor.gd")

signal activated(checkpoint_position: Vector2)

var is_activated: bool = false
var _glow: Polygon2D
var _rune: Polygon2D


func _ready() -> void:
	_glow = $Glow
	_rune = $Rune
	body_entered.connect(_on_body_entered)


func activate() -> void:
	if is_activated:
		return
	is_activated = true
	_glow.color = Color(0.18, 0.82, 1.0, 0.48)
	_rune.color = Color(0.63, 0.94, 1.0, 1.0)
	activated.emit(global_position + Vector2(0.0, -5.0))


func reset_checkpoint() -> void:
	is_activated = false
	_glow.color = Color(0.15, 0.52, 0.82, 0.17)
	_rune.color = Color(0.38, 0.75, 0.95, 0.72)


func _on_body_entered(body: Node2D) -> void:
	var actor: ActorScript = body as ActorScript
	if actor == null or actor.is_echo:
		return
	activate()
