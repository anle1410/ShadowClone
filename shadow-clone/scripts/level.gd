class_name GameLevel
extends Node2D

const Visuals = preload("res://scripts/game_visuals.gd")
const RecordedActionScript = preload("res://scripts/recorded_action.gd")
const CheckpointScript = preload("res://scripts/checkpoint.gd")
const SpikeTrapScript = preload("res://scripts/spike_trap.gd")

signal status_changed(message: String)
signal level_finished(won: bool, message: String)
signal recording_progress_changed(elapsed_seconds: float, limit_seconds: float, visible: bool)

const ACTOR_SCENE: PackedScene = preload("res://scenes/game_actor.tscn")
const ActorScript = preload("res://scripts/game_actor.gd")
const MAX_RECORD_SECONDS: float = 8.0
const FALL_LIMIT: float = 790.0
const PLATFORM_SCENE_COLOR: Color = Color(0.09, 0.105, 0.17, 1.0)
const START_POSITION: Vector2 = Vector2(115.0, 565.0)

@onready var _player: ActorScript = $Player
@onready var _plate: PressurePlate = $PressurePlate
@onready var _door: ExitDoor = $ExitDoor
@onready var _checkpoint: CheckpointScript = $Checkpoint
@onready var _spike_trap: SpikeTrapScript = $SpikeTrap

var _active: bool = false
var _recording: bool = false
var _respawning: bool = false
var _transition_locked: bool = false
var _respawn_generation: int = 0
var _recorded_actions: Array[RecordedActionScript] = []
var _pending_actions: Array[RecordedActionScript] = []
var _record_start_position: Vector2 = Vector2.ZERO
var _checkpoint_position: Vector2 = START_POSITION
var _echo: ActorScript
var _touch_left: bool = false
var _touch_right: bool = false
var _touch_jump: bool = false
var _recording_elapsed: float = 0.0
var _progress_refresh: float = 0.0


func _ready() -> void:
	_build_room()
	_player.action_sampled.connect(_on_player_action_sampled)
	_plate.activated_changed.connect(_on_plate_activated_changed)
	_door.exit_reached.connect(_on_exit_reached)
	_checkpoint.activated.connect(_on_checkpoint_activated)
	_spike_trap.actor_triggered.connect(_on_spike_triggered)
	_player.reset_actor(START_POSITION)
	_set_status("Sẵn sàng · R ghi/dừng · E tạo bóng · Q xóa bóng")


func _process(delta: float) -> void:
	if _active and _recording:
		_recording_elapsed = minf(_recording_elapsed + delta, MAX_RECORD_SECONDS)
		_progress_refresh += delta
		if _progress_refresh >= 0.1:
			_progress_refresh = 0.0
			recording_progress_changed.emit(_recording_elapsed, MAX_RECORD_SECONDS, true)
		if _recording_elapsed >= MAX_RECORD_SECONDS:
			_finish_recording()
	if _active and not _respawning and not _transition_locked and _player.global_position.y > FALL_LIMIT:
		_handle_failure("Bạn đã rơi xuống hố")


func _unhandled_input(event: InputEvent) -> void:
	if not _active or _respawning or _transition_locked or not event is InputEventKey:
		return
	var key_event: InputEventKey = event as InputEventKey
	if key_event.pressed and not key_event.echo:
		if key_event.keycode == KEY_R:
			toggle_recording()
		elif key_event.keycode == KEY_E:
			spawn_echo()
		elif key_event.keycode == KEY_Q:
			remove_echo()
		elif key_event.keycode == KEY_ESCAPE:
			level_finished.emit(false, "Tạm dừng")


func set_active(value: bool) -> void:
	_active = value
	var actor_active: bool = value and not _respawning and not _transition_locked
	_player.input_enabled = actor_active
	_player.set_physics_process(actor_active)
	if is_instance_valid(_echo):
		_echo.set_physics_process(actor_active)
	if not value:
		_player.set_touch_controls(false, false, false)
		_touch_left = false
		_touch_right = false
		_touch_jump = false


func set_touch_controls(left: bool, right: bool, jump: bool) -> void:
	if _respawning or _transition_locked:
		_player.set_touch_controls(false, false, false)
		return
	_touch_left = left
	_touch_right = right
	_touch_jump = jump
	_player.set_touch_controls(left, right, jump)


func reset_level() -> void:
	set_active(false)
	_respawn_generation += 1
	_respawning = false
	_transition_locked = false
	_recording = false
	_recorded_actions.clear()
	_pending_actions.clear()
	_recording_elapsed = 0.0
	_progress_refresh = 0.0
	_record_start_position = START_POSITION
	_checkpoint_position = START_POSITION
	_checkpoint.reset_checkpoint()
	_spike_trap.reset_trap()
	remove_echo(false)
	_plate.reset_state()
	_plate.set_visual_active(false)
	_door.set_open(false)
	_player.reset_actor(_record_start_position)
	recording_progress_changed.emit(0.0, MAX_RECORD_SECONDS, false)
	_set_status("Sẵn sàng · R ghi/dừng · E tạo bóng · Q xóa bóng")


func toggle_recording() -> void:
	if not _active or _respawning or _transition_locked:
		return
	if _recording:
		_finish_recording()
		return

	_pending_actions.clear()
	_record_start_position = _player.global_position
	_recording_elapsed = 0.0
	_progress_refresh = 0.0
	_recording = true
	_player.set_recording_visual(true)
	recording_progress_changed.emit(0.0, MAX_RECORD_SECONDS, true)
	if not _recorded_actions.is_empty():
		_set_status("ĐANG GHI LẠI · Bản cũ được giữ đến khi ghi xong")
	else:
		_set_status("ĐANG GHI · R dừng, tối đa 8 giây")


func _finish_recording() -> void:
	if not _recording:
		return
	_recording = false
	_player.set_recording_visual(false)
	recording_progress_changed.emit(_recording_elapsed, MAX_RECORD_SECONDS, false)
	if _pending_actions.is_empty():
		if _recorded_actions.is_empty():
			_set_status("Chưa có hành động được ghi · Hãy di chuyển rồi thử lại")
		else:
			_set_status("Bản ghi mới trống · Bản ghi cũ vẫn được giữ")
		return

	_recorded_actions = _pending_actions.duplicate()
	_pending_actions.clear()
	_set_status("ĐÃ GHI %.1f GIÂY · Nhấn E để tạo bóng" % _recording_elapsed)


func spawn_echo() -> void:
	if not _active or _respawning or _transition_locked:
		return
	if _recording:
		_set_status("Dừng ghi bằng R trước khi tạo bóng")
		return
	if _recorded_actions.is_empty():
		_set_status("Chưa có bản ghi · Nhấn R để ghi hành động trước")
		return

	remove_echo(false)
	_echo = ACTOR_SCENE.instantiate() as ActorScript
	_echo.name = "Echo"
	_echo.is_echo = true
	add_child(_echo)
	_echo.replay_finished.connect(_on_echo_replay_finished)
	_echo.begin_replay(_recorded_actions, _record_start_position)
	_set_status("ĐANG PHÁT LẠI · Bóng lặp chuỗi đã ghi")


func remove_echo(show_status: bool = true) -> void:
	if not is_instance_valid(_echo):
		_echo = null
		if show_status:
			_set_status("Không có bóng để xóa")
		return

	_plate.forget_actor(_echo)
	Visuals.spawn_ring(
		self,
		to_local(_echo.global_position),
		Color(0.2, 0.82, 1.0, 0.65),
		8.0,
		0.22
	)
	_echo.dissolve_echo()
	_echo = null
	if show_status:
		_set_status("ĐÃ XÓA BÓNG · Bản ghi vẫn được giữ")


func _on_echo_replay_finished() -> void:
	if is_instance_valid(_echo) and _active:
		_set_status("BÓNG ĐÃ DỪNG · Nhấn E để phát lại, Q để xóa")


func _on_player_action_sampled(
	axis: float,
	jump_pressed: bool,
	world_position: Vector2,
	actor_velocity: Vector2,
	grounded: bool
) -> void:
	if not _recording:
		return
	var tick_rate: float = float(Engine.physics_ticks_per_second)
	var elapsed: float = float(_pending_actions.size()) / tick_rate
	_pending_actions.append(RecordedActionScript.new(
		elapsed,
		world_position - _record_start_position,
		axis,
		jump_pressed,
		grounded,
		actor_velocity
	))
	var frame_limit: int = int(MAX_RECORD_SECONDS * tick_rate)
	if _pending_actions.size() >= frame_limit:
		_recording_elapsed = MAX_RECORD_SECONDS
		_finish_recording()


func _on_plate_activated_changed(is_active: bool) -> void:
	_door.set_open(is_active)
	if is_active:
		_set_status("CÔNG TẮC ĐANG ĐƯỢC GIỮ · Cửa đã mở!")
	elif is_instance_valid(_echo):
		_set_status("Công tắc đã nhả · Ghi chuỗi khác bằng R")


func _on_exit_reached() -> void:
	if _active and not _respawning and not _transition_locked and _door.is_open:
		_transition_locked = true
		set_active(false)
		level_finished.emit(true, "Tuyệt vời! Bạn đã phối hợp cùng bóng để thoát.")


func _on_checkpoint_activated(checkpoint_world_position: Vector2) -> void:
	if not _respawning and not _transition_locked:
		_checkpoint_position = checkpoint_world_position
		_set_status("CHECKPOINT ĐÃ KÍCH HOẠT · Hồi sinh tại cột rune")


func _on_spike_triggered(actor: Node2D) -> void:
	if actor == _player:
		_handle_failure("Bạn đã chạm phải bẫy gai")


func _handle_failure(reason: String) -> void:
	if not _active or _respawning or _transition_locked:
		return
	_respawn_generation += 1
	var current_generation: int = _respawn_generation
	_respawning = true
	_recording = false
	_pending_actions.clear()
	_recorded_actions.clear()
	_record_start_position = _checkpoint_position
	_recording_elapsed = 0.0
	_progress_refresh = 0.0
	_player.set_recording_visual(false)
	_player.set_touch_controls(false, false, false)
	_player.input_enabled = false
	_player.set_physics_process(false)
	recording_progress_changed.emit(0.0, MAX_RECORD_SECONDS, false)
	remove_echo(false)
	_plate.reset_state()
	_plate.set_visual_active(false)
	_door.set_open(false)
	_spike_trap.reset_trap()
	Visuals.spawn_ring(
		self,
		to_local(_player.global_position),
		Color(0.35, 0.79, 1.0, 0.72),
		10.0,
		0.3
	)
	_set_status("%s · Đang hồi sinh..." % reason)
	_respawn_at_checkpoint(current_generation)


func _respawn_at_checkpoint(generation: int) -> void:
	await get_tree().create_timer(0.3).timeout
	if not is_inside_tree() or generation != _respawn_generation or _transition_locked:
		return
	_player.reset_actor(_checkpoint_position)
	_player.input_enabled = _active
	_player.set_physics_process(_active)
	_respawning = false
	_touch_left = false
	_touch_right = false
	_touch_jump = false
	_spike_trap.reset_trap()
	_set_status("ĐÃ HỒI SINH · R ghi/dừng · E tạo bóng · Q xóa bóng")


func _set_status(message: String) -> void:
	status_changed.emit(message)


func _build_room() -> void:
	_add_platform(Vector2(260.0, 610.0), Vector2(520.0, 40.0))
	_add_platform(Vector2(1000.0, 610.0), Vector2(530.0, 40.0))
	_add_platform(Vector2(-20.0, 330.0), Vector2(40.0, 660.0))
	_add_platform(Vector2(1300.0, 330.0), Vector2(40.0, 660.0))
	_add_platform(Vector2(640.0, 70.0), Vector2(1280.0, 40.0))
	queue_redraw()


func _add_platform(center: Vector2, dimensions: Vector2) -> void:
	var body: StaticBody2D = StaticBody2D.new()
	body.position = center
	var shape_node: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = dimensions
	shape_node.shape = shape
	body.add_child(shape_node)

	var visual: Polygon2D = Polygon2D.new()
	var half_size: Vector2 = dimensions * 0.5
	visual.polygon = PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y)
	])
	visual.color = PLATFORM_SCENE_COLOR
	body.add_child(visual)

	if dimensions.x > 400.0 and center.y > 500.0:
		_add_ground_details(body, dimensions)
	add_child(body)


func _add_ground_details(body: StaticBody2D, dimensions: Vector2) -> void:
	var half_width: float = dimensions.x * 0.5
	var half_height: float = dimensions.y * 0.5
	var top_edge: Line2D = Line2D.new()
	top_edge.points = PackedVector2Array([
		Vector2(-half_width, -half_height),
		Vector2(half_width, -half_height)
	])
	top_edge.width = 3.0
	top_edge.default_color = Color(0.29, 0.36, 0.51, 1.0)
	body.add_child(top_edge)

	for tile_index: int in range(int(dimensions.x / 105.0) + 1):
		var tile_left: float = -half_width + float(tile_index) * 105.0
		var tile_width: float = minf(105.0, half_width - tile_left)
		if tile_width < 28.0:
			continue

		var stone_face: Polygon2D = Polygon2D.new()
		stone_face.polygon = PackedVector2Array([
			Vector2(tile_left + 2.0, -half_height + 3.0),
			Vector2(tile_left + tile_width - 3.0, -half_height + 3.0),
			Vector2(tile_left + tile_width - 1.0, half_height - 3.0),
			Vector2(tile_left + tile_width * 0.55, half_height - 1.0),
			Vector2(tile_left + 2.0, half_height - 4.0)
		])
		var face_shade: float = float(tile_index % 3) * 0.008
		stone_face.color = Color(
			0.1 + face_shade,
			0.115 + face_shade,
			0.185 + face_shade,
			1.0
		)
		body.add_child(stone_face)

		var seam: Line2D = Line2D.new()
		seam.points = PackedVector2Array([
			Vector2(tile_left + tile_width - 5.0, -half_height + 6.0),
			Vector2(tile_left + tile_width, -half_height + 12.0),
			Vector2(tile_left + tile_width - 3.0, -half_height + 18.0)
		])
		seam.width = 1.4
		seam.default_color = Color(0.035, 0.043, 0.08, 0.88)
		body.add_child(seam)

		var worn_edge: Line2D = Line2D.new()
		worn_edge.points = PackedVector2Array([
			Vector2(tile_left + 10.0, -half_height + 8.0),
			Vector2(tile_left + tile_width * 0.32, -half_height + 7.0),
			Vector2(tile_left + tile_width * 0.52, -half_height + 9.0)
		])
		worn_edge.width = 1.0
		worn_edge.default_color = Color(0.26, 0.33, 0.47, 0.28)
		body.add_child(worn_edge)

		var upper_seam: Line2D = Line2D.new()
		upper_seam.points = PackedVector2Array([
			Vector2(tile_left + 12.0, -half_height + 12.0),
			Vector2(tile_left + tile_width * 0.36, -half_height + 11.0),
			Vector2(tile_left + tile_width * 0.58, -half_height + 13.0)
		])
		upper_seam.width = 1.0
		upper_seam.default_color = Color(0.34, 0.41, 0.56, 0.19)
		body.add_child(upper_seam)

		if tile_index % 3 == 1:
			var moss: Polygon2D = Polygon2D.new()
			moss.polygon = PackedVector2Array([
				Vector2(tile_left + 12.0, -half_height),
				Vector2(tile_left + 21.0, -half_height - 3.0),
				Vector2(tile_left + 36.0, -half_height - 2.0),
				Vector2(tile_left + 43.0, -half_height)
			])
			moss.color = Color(0.17, 0.37, 0.34, 0.95)
			body.add_child(moss)

			var moss_shadow: Polygon2D = Polygon2D.new()
			moss_shadow.polygon = PackedVector2Array([
				Vector2(tile_left + 18.0, -half_height + 1.0),
				Vector2(tile_left + 23.0, -half_height + 2.0),
				Vector2(tile_left + 35.0, -half_height + 1.0)
			])
			moss_shadow.color = Color(0.08, 0.2, 0.2, 0.8)
			body.add_child(moss_shadow)

		if tile_index % 2 == 0:
			var inner_seam: Line2D = Line2D.new()
			inner_seam.points = PackedVector2Array([
				Vector2(tile_left + 25.0, -half_height + 25.0),
				Vector2(tile_left + 31.0, -half_height + 29.0),
				Vector2(tile_left + 29.0, -half_height + 34.0)
			])
			inner_seam.width = 1.0
			inner_seam.default_color = Color(0.045, 0.052, 0.095, 0.82)
			body.add_child(inner_seam)

		var mineral_speck: Polygon2D = Polygon2D.new()
		mineral_speck.position = Vector2(
			tile_left + tile_width * (0.58 if tile_index % 2 == 0 else 0.72),
			-half_height + 19.0
		)
		mineral_speck.polygon = PackedVector2Array([
			Vector2(-2.0, 0.0), Vector2(0.0, -1.5), Vector2(2.0, 0.0),
			Vector2(0.0, 1.5)
		])
		mineral_speck.color = Color(0.42, 0.68, 0.71, 0.34)
		body.add_child(mineral_speck)

	var lower_edge: Line2D = Line2D.new()
	lower_edge.points = PackedVector2Array([
		Vector2(-half_width + 2.0, half_height - 3.0),
		Vector2(half_width - 2.0, half_height - 3.0)
	])
	lower_edge.width = 2.0
	lower_edge.default_color = Color(0.025, 0.035, 0.07, 0.88)
	body.add_child(lower_edge)
