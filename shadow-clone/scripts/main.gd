extends Node2D

const LevelScript = preload("res://scripts/level.gd")
const HudScript = preload("res://scripts/hud.gd")

@onready var _level: LevelScript = $Level
@onready var _hud: HudScript = $HUD


func _ready() -> void:
	_hud.start_pressed.connect(_start_game)
	_hud.record_pressed.connect(_level.toggle_recording)
	_hud.echo_pressed.connect(_level.spawn_echo)
	_hud.restart_pressed.connect(_restart_game)
	_hud.pause_pressed.connect(_pause_game)
	_hud.resume_pressed.connect(_resume_game)
	_hud.menu_pressed.connect(_return_to_menu)
	_level.status_changed.connect(_hud.set_game_status)
	_level.recording_progress_changed.connect(_hud.set_recording_progress)
	_level.level_finished.connect(_on_level_finished)
	_level.set_active(false)
	_hud.show_menu()


func _process(_delta: float) -> void:
	_level.set_touch_controls(
		_hud.left_pressed,
		_hud.right_pressed,
		_hud.jump_pressed
	)


func _start_game() -> void:
	_level.reset_level()
	_level.set_active(true)
	_hud.show_game()


func _restart_game() -> void:
	_start_game()


func _pause_game() -> void:
	_level.set_active(false)
	_hud.show_pause()


func _resume_game() -> void:
	_level.set_active(true)
	_hud.show_game()


func _return_to_menu() -> void:
	_level.reset_level()
	_level.set_active(false)
	_hud.show_menu()


func _on_level_finished(won: bool, message: String) -> void:
	_level.set_active(false)
	if message == "Tạm dừng":
		_hud.show_pause()
		return
	_hud.show_result(won, message)
