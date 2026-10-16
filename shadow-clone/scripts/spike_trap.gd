class_name SpikeTrap
extends Area2D

const ActorScript = preload("res://scripts/game_actor.gd")

signal actor_triggered(actor: Node2D)

var _triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func reset_trap() -> void:
	_triggered = false


func _on_body_entered(body: Node2D) -> void:
	var actor: ActorScript = body as ActorScript
	if _triggered or actor == null or actor.is_echo:
		return
	_triggered = true
	actor_triggered.emit(actor)
