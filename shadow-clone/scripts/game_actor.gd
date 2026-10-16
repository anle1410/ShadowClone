class_name GameActor
extends CharacterBody2D

const Visuals = preload("res://scripts/game_visuals.gd")
const RecordedActionScript = preload("res://scripts/recorded_action.gd")

signal action_sampled(
	axis: float,
	jump_pressed: bool,
	world_position: Vector2,
	actor_velocity: Vector2,
	grounded: bool
)
signal replay_finished

const MOVE_SPEED: float = 290.0
const JUMP_SPEED: float = 470.0
const MAX_FALL_SPEED: float = 900.0

@export var is_echo: bool = false

var input_enabled: bool = true
var touch_left: bool = false
var touch_right: bool = false
var touch_jump: bool = false
var _previous_jump_down: bool = false
var _replay_frames: Array[RecordedActionScript] = []
var _replay_index: int = 0
var _replay_completed: bool = false
var _visual_root: Node2D
var _leg_left: Node2D
var _leg_right: Node2D
var _arm_left: Node2D
var _arm_right: Node2D
var _cape: Polygon2D
var _aura: Polygon2D
var _chest_rune: Polygon2D
var _effects_root: Node2D
var _echo_light: PointLight2D
var _echo_trail: Line2D
var _echo_transition_tween: Tween
var _trail_points: Array[Vector2] = []
var _trail_timer: float = 0.0
var _animation_time: float = 0.0
var _landing_time: float = 0.0
var _recording_visual: bool = false
var _is_dissolving: bool = false


func _ready() -> void:
	_visual_root = $Visual
	_leg_left = $Visual/LegLeft
	_leg_right = $Visual/LegRight
	_arm_left = $Visual/ArmLeft
	_arm_right = $Visual/ArmRight
	_cape = $Visual/Cape
	_aura = $Visual/Aura
	_chest_rune = $Visual/ChestRune
	_effects_root = $ImpactEffects
	_visual_root.modulate = Color(0.54, 0.91, 1.0, 0.72) if is_echo else Color.WHITE
	_echo_light = Visuals.create_light(
		self,
		Color(0.2, 0.73, 1.0, 1.0),
		0.42 if is_echo else 0.2,
		0.72 if is_echo else 0.48
	)
	_echo_light.position = Vector2(0.0, -3.0)
	if is_echo:
		_create_echo_trail()


func _physics_process(delta: float) -> void:
	var axis: float = 0.0
	var jump_pressed: bool = false

	if is_echo:
		if _replay_index < _replay_frames.size():
			var frame: RecordedAction = _replay_frames[_replay_index]
			axis = frame.horizontal_input
			jump_pressed = frame.jump_pressed
			_replay_index += 1
		# Khi hết frame, trục ngang bằng 0 nên bóng dừng tại công tắc.
	else:
		if input_enabled:
			var left_down: bool = (
				Input.is_physical_key_pressed(KEY_A)
				or Input.is_physical_key_pressed(KEY_LEFT)
				or touch_left
			)
			var right_down: bool = (
				Input.is_physical_key_pressed(KEY_D)
				or Input.is_physical_key_pressed(KEY_RIGHT)
				or touch_right
			)
			axis = (1.0 if right_down else 0.0) - (1.0 if left_down else 0.0)
			var jump_down: bool = (
				Input.is_physical_key_pressed(KEY_SPACE)
				or touch_jump
			)
			jump_pressed = jump_down and not _previous_jump_down
			_previous_jump_down = jump_down
		else:
			_previous_jump_down = false

	velocity.x = axis * MOVE_SPEED
	if is_on_floor() and jump_pressed:
		velocity.y = -JUMP_SPEED
	velocity.y = minf(velocity.y + get_gravity().y * delta, MAX_FALL_SPEED)
	var was_grounded: bool = is_on_floor()
	var incoming_vertical_speed: float = velocity.y
	move_and_slide()
	_animate_visual(delta, was_grounded, incoming_vertical_speed)
	if is_echo:
		_update_echo_trail(delta)
		if not _replay_completed and not _replay_frames.is_empty():
			if _replay_index >= _replay_frames.size():
				_replay_completed = true
				replay_finished.emit()
	elif input_enabled:
		action_sampled.emit(axis, jump_pressed, global_position, velocity, is_on_floor())


func _animate_visual(delta: float, was_grounded: bool, incoming_vertical_speed: float) -> void:
	_animation_time += delta
	if absf(velocity.x) > 1.0:
		_visual_root.scale.x = signf(velocity.x)

	var grounded: bool = is_on_floor()
	if grounded and not was_grounded and incoming_vertical_speed > 100.0:
		_landing_time = 0.14
		_spawn_landing_effect()
	_landing_time = maxf(_landing_time - delta, 0.0)

	var target_leg_left: float = 0.0
	var target_leg_right: float = 0.0
	var target_arm_left: float = 0.0
	var target_arm_right: float = 0.0
	var target_root_y: float = 0.0
	var target_root_rotation: float = 0.0
	var target_root_scale_y: float = 1.0
	var target_cape_rotation: float = 0.0
	if grounded and absf(velocity.x) > 8.0:
		var stride: float = sin(_animation_time * 15.0)
		target_leg_left = stride * 0.4
		target_leg_right = -stride * 0.4
		target_arm_left = -stride * 0.22
		target_arm_right = stride * 0.22
		target_root_y = absf(stride) * 1.5
		target_root_rotation = stride * 0.025
		target_root_scale_y = 1.0 - absf(stride) * 0.018
		target_cape_rotation = -0.08 + stride * 0.13
	elif not grounded and velocity.y < -20.0:
		target_leg_left = -0.24
		target_leg_right = 0.22
		target_arm_left = -0.52
		target_arm_right = 0.38
		target_root_y = -1.0
		target_root_rotation = -0.025
		target_cape_rotation = 0.2
	elif not grounded:
		target_leg_left = 0.28
		target_leg_right = -0.22
		target_arm_left = 0.24
		target_arm_right = -0.3
		target_root_rotation = 0.035
		target_cape_rotation = -0.12
	elif _landing_time <= 0.0:
		var breath: float = sin(_animation_time * 2.4)
		target_root_y = breath * 0.7
		target_root_scale_y = 1.0 + breath * 0.008
		target_cape_rotation = sin(_animation_time * 1.8) * 0.045

	if _landing_time > 0.0:
		var landing_amount: float = _landing_time / 0.14
		target_root_scale_y *= 1.0 - landing_amount * 0.08
		target_root_y += landing_amount * 1.5

	# Làm mượt pose hình ảnh; không tác động đến CharacterBody2D hoặc dữ liệu replay.
	var pose_blend: float = minf(delta * 20.0, 1.0)
	_leg_left.rotation = lerpf(_leg_left.rotation, target_leg_left, pose_blend)
	_leg_right.rotation = lerpf(_leg_right.rotation, target_leg_right, pose_blend)
	_arm_left.rotation = lerpf(_arm_left.rotation, target_arm_left, pose_blend)
	_arm_right.rotation = lerpf(_arm_right.rotation, target_arm_right, pose_blend)
	_visual_root.position.y = lerpf(_visual_root.position.y, target_root_y, pose_blend)
	_visual_root.rotation = lerp_angle(_visual_root.rotation, target_root_rotation, pose_blend)
	_visual_root.scale.y = lerpf(_visual_root.scale.y, target_root_scale_y, pose_blend)
	_cape.rotation = lerpf(_cape.rotation, target_cape_rotation, pose_blend)

	var aura_color: Color = Color(0.29, 0.75, 0.98, 0.09)
	if is_echo:
		aura_color = Color(0.24, 0.88, 1.0, 0.19 + sin(_animation_time * 4.0) * 0.025)
	elif _recording_visual:
		aura_color = Color(0.25, 0.77, 1.0, 0.2 + sin(_animation_time * 7.0) * 0.035)
	_aura.color = aura_color
	if _recording_visual:
		var rune_pulse: float = 0.75 + (sin(_animation_time * 7.0) + 1.0) * 0.12
		_chest_rune.color = Color(0.32, 0.86, 1.0, rune_pulse)
	elif is_echo:
		_chest_rune.color = Color(0.25, 0.88, 1.0, 0.94)
	else:
		_chest_rune.color = Color(0.35, 0.83, 1.0, 0.95)


func set_recording_visual(active: bool) -> void:
	_recording_visual = active and not is_echo


func _create_echo_trail() -> void:
	_echo_trail = Line2D.new()
	_echo_trail.name = "EchoTrail"
	_echo_trail.z_index = -2
	_echo_trail.width = 7.0
	_echo_trail.default_color = Color(0.2, 0.84, 1.0, 0.31)
	_echo_trail.antialiased = true
	var trail_gradient: Gradient = Gradient.new()
	trail_gradient.colors = PackedColorArray([
		Color(0.35, 0.92, 1.0, 0.52),
		Color(0.2, 0.7, 1.0, 0.0)
	])
	_echo_trail.gradient = trail_gradient
	add_child(_echo_trail)


func _update_echo_trail(delta: float) -> void:
	_trail_timer += delta
	if _trail_timer < 0.035:
		return
	_trail_timer = 0.0
	_trail_points.push_front(global_position)
	while _trail_points.size() > 7:
		_trail_points.pop_back()

	_echo_trail.clear_points()
	for world_position: Vector2 in _trail_points:
		_echo_trail.add_point(to_local(world_position))


func set_echo_emphasis(active: bool) -> void:
	if not is_echo or _is_dissolving:
		return
	if _echo_transition_tween != null and _echo_transition_tween.is_running():
		_echo_transition_tween.kill()
	var target_energy: float = 1.1 if active else 0.42
	var target_alpha: float = 0.31 if active else 0.19
	_echo_transition_tween = create_tween()
	_echo_transition_tween.set_parallel(true)
	_echo_transition_tween.tween_property(_echo_light, "energy", target_energy, 0.18)
	_echo_transition_tween.tween_property(_aura, "color:a", target_alpha, 0.18)
	_echo_transition_tween.tween_property(_visual_root, "modulate:a", 0.72, 0.18)


func dissolve_echo() -> void:
	if not is_echo or not is_inside_tree():
		queue_free()
		return
	_is_dissolving = true
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)
	if _echo_transition_tween != null and _echo_transition_tween.is_running():
		_echo_transition_tween.kill()
	_echo_transition_tween = create_tween()
	_echo_transition_tween.finished.connect(queue_free)
	_echo_transition_tween.set_parallel(true)
	_echo_transition_tween.tween_property(_visual_root, "modulate:a", 0.0, 0.2)
	_echo_transition_tween.tween_property(_echo_light, "energy", 0.0, 0.2)
	_echo_transition_tween.tween_property(_echo_trail, "modulate:a", 0.0, 0.16)


func _spawn_landing_effect() -> void:
	var ring: Line2D = Line2D.new()
	var ring_points: PackedVector2Array = []
	for point_index: int in range(17):
		var angle: float = TAU * float(point_index) / 16.0
		ring_points.append(Vector2(cos(angle) * 7.0, sin(angle) * 2.4 + 19.0))
	ring.points = ring_points
	ring.width = 2.0
	ring.default_color = Color(0.36, 0.79, 0.96, 0.8)
	ring.closed = true
	_effects_root.add_child(ring)

	var ring_tween: Tween = create_tween()
	ring_tween.set_parallel(true)
	ring_tween.tween_property(ring, "scale", Vector2(2.8, 2.0), 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	ring_tween.tween_property(ring, "modulate:a", 0.0, 0.26)
	ring_tween.chain().tween_callback(ring.queue_free)

	for chip_index: int in range(3):
		var chip: Polygon2D = Polygon2D.new()
		chip.polygon = PackedVector2Array([
			Vector2(0.0, -2.0),
			Vector2(2.0, 0.0),
			Vector2(0.0, 2.0),
			Vector2(-2.0, 0.0)
		])
		chip.color = Color(0.35, 0.59, 0.74, 0.8)
		chip.position = Vector2(float(chip_index - 1) * 7.0, 18.0)
		_effects_root.add_child(chip)

		var direction: float = float(chip_index - 1)
		var chip_tween: Tween = create_tween()
		chip_tween.set_parallel(true)
		chip_tween.tween_property(
			chip,
			"position",
			chip.position + Vector2(direction * 9.0, -8.0 - absf(direction) * 2.0),
			0.24
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		chip_tween.tween_property(chip, "modulate:a", 0.0, 0.24)
		chip_tween.chain().tween_callback(chip.queue_free)


func set_touch_controls(left: bool, right: bool, jump: bool) -> void:
	touch_left = left
	touch_right = right
	touch_jump = jump


func begin_replay(frames: Array[RecordedActionScript], start_position: Vector2) -> void:
	is_echo = true
	global_position = start_position
	velocity = Vector2.ZERO
	_replay_frames = frames.duplicate()
	_replay_index = 0
	_replay_completed = false
	_visual_root.modulate = Color(0.54, 0.91, 1.0, 0.0)
	_echo_light.energy = 0.42
	if not is_instance_valid(_echo_trail):
		_create_echo_trail()
	_echo_trail.modulate.a = 1.0
	if _echo_transition_tween != null and _echo_transition_tween.is_running():
		_echo_transition_tween.kill()
	_echo_transition_tween = create_tween()
	_echo_transition_tween.set_parallel(true)
	_echo_transition_tween.tween_property(_visual_root, "modulate:a", 0.72, 0.18)
	_echo_transition_tween.tween_property(_echo_light, "energy", 0.42, 0.2)
	Visuals.spawn_ring(get_parent(), global_position, Color(0.27, 0.88, 1.0, 0.82), 9.0, 0.3)


func reset_actor(start_position: Vector2) -> void:
	global_position = start_position
	velocity = Vector2.ZERO
	_landing_time = 0.0
	_recording_visual = false
	_previous_jump_down = false
	_replay_frames.clear()
	_replay_index = 0
	_replay_completed = false
	touch_left = false
	touch_right = false
	touch_jump = false
	is_echo = false
	if is_instance_valid(_echo_trail):
		_echo_trail.queue_free()
	if is_instance_valid(_visual_root):
		_visual_root.modulate = Color.WHITE
		_visual_root.scale.y = 1.0
		_visual_root.rotation = 0.0
