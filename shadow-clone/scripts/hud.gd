class_name GameHud
extends Control

signal start_pressed
signal record_pressed
signal echo_pressed
signal restart_pressed
signal pause_pressed
signal resume_pressed
signal menu_pressed

var left_pressed: bool = false
var right_pressed: bool = false
var jump_pressed: bool = false

var _status_label: Label
var _overlay_center: CenterContainer
var _menu_panel: PanelContainer
var _pause_panel: PanelContainer
var _result_panel: PanelContainer
var _result_title: Label
var _result_message: Label
var _record_progress: ProgressBar
var _record_timer_label: Label
var _status_tween: Tween
var _panel_tween: Tween
var _touch_buttons: Array[Button] = []
var _game_buttons: Array[Button] = []
var _overlay_panels: Array[PanelContainer] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_hud()
	resized.connect(_queue_overlay_layout)
	_queue_overlay_layout()
	show_menu()


func show_menu() -> void:
	_reset_touch()
	_menu_panel.show()
	_pause_panel.hide()
	_result_panel.hide()
	_queue_panel_animation(_menu_panel)
	_status_label.hide()
	_set_record_ui_visible(false)
	_set_touch_visible(false)
	_set_game_buttons_visible(false)


func show_game() -> void:
	_reset_touch()
	_menu_panel.hide()
	_pause_panel.hide()
	_result_panel.hide()
	_status_label.show()
	_set_touch_visible(true)
	_set_game_buttons_visible(true)


func show_pause() -> void:
	_reset_touch()
	_menu_panel.hide()
	_result_panel.hide()
	_pause_panel.show()
	_queue_panel_animation(_pause_panel)
	_set_touch_visible(false)
	_set_game_buttons_visible(false)


func show_result(won: bool, message: String) -> void:
	_reset_touch()
	_result_title.text = "CHIẾN THẮNG" if won else "THỬ LẠI"
	_result_message.text = message
	_result_title.add_theme_color_override(
		"font_color",
		Color(0.52, 0.91, 0.82, 1.0) if won else Color(0.78, 0.7, 0.9, 1.0)
	)
	_menu_panel.hide()
	_pause_panel.hide()
	_result_panel.show()
	_queue_panel_animation(_result_panel)
	_set_record_ui_visible(false)
	_set_touch_visible(false)
	_set_game_buttons_visible(false)
	_queue_overlay_layout()


func set_game_status(message: String) -> void:
	if is_instance_valid(_status_label):
		if _status_label.text == message:
			return
		if _status_tween != null and _status_tween.is_running():
			_status_tween.kill()
		_status_tween = create_tween()
		_status_tween.tween_property(_status_label, "modulate:a", 0.3, 0.07)
		_status_tween.tween_callback(func() -> void: _status_label.text = message)
		_status_tween.tween_property(_status_label, "modulate:a", 1.0, 0.12)


func set_recording_progress(elapsed: float, limit: float, show_progress: bool) -> void:
	_set_record_ui_visible(show_progress)
	if not show_progress:
		return
	_record_progress.max_value = limit
	_record_progress.value = elapsed
	_record_timer_label.text = "%0.1f / %0.1f s" % [elapsed, limit]


func _build_hud() -> void:
	_status_label = Label.new()
	_status_label.position = Vector2(22.0, 14.0)
	_status_label.size = Vector2(700.0, 38.0)
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 19)
	_status_label.add_theme_color_override("font_color", Color(0.68, 0.88, 1.0, 1.0))
	_status_label.add_theme_color_override("font_outline_color", Color(0.025, 0.035, 0.075, 0.95))
	_status_label.add_theme_constant_override("outline_size", 3)
	var status_panel: StyleBoxFlat = StyleBoxFlat.new()
	status_panel.bg_color = Color(0.025, 0.04, 0.08, 0.72)
	status_panel.border_color = Color(0.23, 0.37, 0.55, 0.64)
	status_panel.set_border_width_all(1)
	status_panel.set_corner_radius_all(8)
	status_panel.content_margin_left = 12.0
	status_panel.content_margin_right = 12.0
	status_panel.content_margin_top = 4.0
	status_panel.content_margin_bottom = 4.0
	_status_label.add_theme_stylebox_override("normal", status_panel)
	add_child(_status_label)

	_record_progress = ProgressBar.new()
	_record_progress.position = Vector2(24.0, 53.0)
	_record_progress.size = Vector2(178.0, 8.0)
	_record_progress.show_percentage = false
	_record_progress.min_value = 0.0
	_record_progress.max_value = 8.0
	var progress_background: StyleBoxFlat = StyleBoxFlat.new()
	progress_background.bg_color = Color(0.06, 0.09, 0.15, 0.9)
	progress_background.set_corner_radius_all(4)
	_record_progress.add_theme_stylebox_override("background", progress_background)
	var progress_fill: StyleBoxFlat = StyleBoxFlat.new()
	progress_fill.bg_color = Color(0.27, 0.79, 0.96, 1.0)
	progress_fill.set_corner_radius_all(4)
	_record_progress.add_theme_stylebox_override("fill", progress_fill)
	add_child(_record_progress)

	_record_timer_label = Label.new()
	_record_timer_label.position = Vector2(212.0, 45.0)
	_record_timer_label.add_theme_font_size_override("font_size", 13)
	_record_timer_label.add_theme_color_override("font_color", Color(0.68, 0.86, 0.98, 1.0))
	_record_timer_label.add_theme_color_override("font_outline_color", Color(0.025, 0.035, 0.075, 0.95))
	_record_timer_label.add_theme_constant_override("outline_size", 2)
	add_child(_record_timer_label)
	_set_record_ui_visible(false)

	var pause_button: Button = _make_button("TẠM DỪNG", Vector2(130.0, 48.0))
	_set_anchor_rect(pause_button, 1.0, 0.0, -154.0, 16.0, -24.0, 64.0)
	pause_button.pressed.connect(pause_pressed.emit)
	add_child(pause_button)
	_game_buttons.append(pause_button)

	var reset_button: Button = _make_button("CHƠI LẠI", Vector2(120.0, 48.0))
	_set_anchor_rect(reset_button, 1.0, 0.0, -286.0, 16.0, -166.0, 64.0)
	reset_button.pressed.connect(restart_pressed.emit)
	add_child(reset_button)
	_game_buttons.append(reset_button)

	var hint: Label = Label.new()
	hint.text = "A/D hoặc ←/→: di chuyển   SPACE: nhảy   R: ghi/dừng   E: tạo bóng   Q: xóa bóng"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_left = 170.0
	hint.offset_right = -170.0
	hint.offset_top = -38.0
	hint.offset_bottom = -8.0
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.73, 0.78, 0.9, 0.96))
	hint.add_theme_color_override("font_outline_color", Color(0.025, 0.035, 0.075, 0.9))
	hint.add_theme_constant_override("outline_size", 3)
	add_child(hint)

	var left_button: Button = _make_button("◀", Vector2(76.0, 76.0))
	_set_anchor_rect(left_button, 0.0, 1.0, 28.0, -104.0, 104.0, -28.0)
	_bind_hold(left_button, "left")
	add_child(left_button)
	_touch_buttons.append(left_button)

	var right_button: Button = _make_button("▶", Vector2(76.0, 76.0))
	_set_anchor_rect(right_button, 0.0, 1.0, 116.0, -104.0, 192.0, -28.0)
	_bind_hold(right_button, "right")
	add_child(right_button)
	_touch_buttons.append(right_button)

	var jump_button: Button = _make_button("NHẢY", Vector2(92.0, 76.0))
	_set_anchor_rect(jump_button, 1.0, 1.0, -212.0, -104.0, -120.0, -28.0)
	_bind_hold(jump_button, "jump")
	add_child(jump_button)
	_touch_buttons.append(jump_button)

	var record_button: Button = _make_button("GHI / DỪNG\n[R]", Vector2(108.0, 76.0))
	_set_anchor_rect(record_button, 1.0, 1.0, -112.0, -104.0, -4.0, -28.0)
	record_button.pressed.connect(record_pressed.emit)
	add_child(record_button)
	_touch_buttons.append(record_button)

	var echo_button: Button = _make_button("TẠO BÓNG\n[E]", Vector2(112.0, 76.0))
	_set_anchor_rect(echo_button, 0.5, 1.0, -56.0, -134.0, 56.0, -58.0)
	echo_button.pressed.connect(echo_pressed.emit)
	add_child(echo_button)
	_touch_buttons.append(echo_button)

	_overlay_center = CenterContainer.new()
	_overlay_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay_center)

	_menu_panel = _make_panel(Vector2(440.0, 380.0))
	var menu_content: VBoxContainer = VBoxContainer.new()
	menu_content.add_theme_constant_override("separation", 15)
	_menu_panel.add_child(menu_content)
	menu_content.add_child(_make_title("SHADOW CLONE"))
	var intro: Label = Label.new()
	intro.text = "Ghi lại hành trình tới công tắc.\nPhát bóng, rồi tự nhảy qua hố tới cửa."
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_content.add_child(intro)
	var controls: Label = Label.new()
	controls.text = "PC: A/D hoặc ←/→ · Space nhảy\nR ghi/dừng · E tạo bóng · Q xóa bóng\nCảm ứng: dùng các nút trên màn hình"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls.add_theme_color_override("font_color", Color(0.72, 0.79, 0.92, 1.0))
	menu_content.add_child(controls)
	var start_button: Button = _make_button("BẮT ĐẦU", Vector2(0.0, 54.0))
	start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_button.pressed.connect(start_pressed.emit)
	menu_content.add_child(start_button)
	_overlay_center.add_child(_menu_panel)

	_pause_panel = _make_panel(Vector2(360.0, 260.0))
	var pause_content: VBoxContainer = VBoxContainer.new()
	pause_content.add_theme_constant_override("separation", 14)
	_pause_panel.add_child(pause_content)
	pause_content.add_child(_make_title("TẠM DỪNG"))
	var resume_button: Button = _make_button("TIẾP TỤC", Vector2(0.0, 50.0))
	resume_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resume_button.pressed.connect(resume_pressed.emit)
	pause_content.add_child(resume_button)
	var pause_restart: Button = _make_button("CHƠI LẠI", Vector2(0.0, 50.0))
	pause_restart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pause_restart.pressed.connect(restart_pressed.emit)
	pause_content.add_child(pause_restart)
	_overlay_center.add_child(_pause_panel)

	_result_panel = _make_panel(Vector2(420.0, 290.0))
	var result_content: VBoxContainer = VBoxContainer.new()
	result_content.add_theme_constant_override("separation", 14)
	_result_panel.add_child(result_content)
	_result_title = _make_title("KẾT THÚC")
	result_content.add_child(_result_title)
	_result_message = Label.new()
	_result_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_content.add_child(_result_message)
	var result_restart: Button = _make_button("CHƠI LẠI MÀN", Vector2(0.0, 50.0))
	result_restart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_restart.pressed.connect(restart_pressed.emit)
	result_content.add_child(result_restart)
	var back_button: Button = _make_button("VỀ MENU", Vector2(0.0, 46.0))
	back_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back_button.pressed.connect(menu_pressed.emit)
	result_content.add_child(back_button)
	_overlay_center.add_child(_result_panel)


func _make_panel(panel_size: Vector2) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = panel_size
	panel.add_theme_constant_override("margin_left", 24)
	panel.add_theme_constant_override("margin_top", 22)
	panel.add_theme_constant_override("margin_right", 24)
	panel.add_theme_constant_override("margin_bottom", 22)
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.045, 0.055, 0.105, 0.97)
	panel_style.border_color = Color(0.27, 0.38, 0.59, 0.9)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(12)
	panel_style.shadow_color = Color(0.01, 0.015, 0.04, 0.45)
	panel_style.shadow_size = 10
	panel.add_theme_stylebox_override("panel", panel_style)
	_overlay_panels.append(panel)
	return panel


func _animate_panel(panel: PanelContainer) -> void:
	if not is_instance_valid(panel) or not panel.visible:
		return
	if _panel_tween != null and _panel_tween.is_running():
		_panel_tween.kill()
	var target_scale: Vector2 = Vector2.ONE * _get_panel_fit_scale(panel)
	panel.pivot_offset = panel.size * 0.5
	panel.scale = target_scale * 0.96
	panel.modulate.a = 0.0
	_panel_tween = create_tween()
	_panel_tween.set_parallel(true)
	_panel_tween.tween_property(panel, "scale", target_scale, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_panel_tween.tween_property(panel, "modulate:a", 1.0, 0.16)


func _queue_panel_animation(panel: PanelContainer) -> void:
	call_deferred("_animate_panel", panel)


func _queue_overlay_layout() -> void:
	call_deferred("_refresh_overlay_layout")


func _refresh_overlay_layout() -> void:
	if not is_instance_valid(_overlay_center):
		return
	for panel: PanelContainer in _overlay_panels:
		var fit_scale: float = _get_panel_fit_scale(panel)
		panel.pivot_offset = panel.size * 0.5
		panel.scale = Vector2.ONE * fit_scale


func _get_panel_fit_scale(panel: PanelContainer) -> float:
	var safe_size: Vector2 = _overlay_center.size - Vector2(32.0, 32.0)
	safe_size.x = maxf(safe_size.x, 1.0)
	safe_size.y = maxf(safe_size.y, 1.0)
	var panel_size: Vector2 = panel.size
	if panel_size.x <= 0.0 or panel_size.y <= 0.0:
		panel_size = panel.custom_minimum_size
	return minf(1.0, minf(safe_size.x / panel_size.x, safe_size.y / panel_size.y))


func _make_title(text: String) -> Label:
	var title: Label = Label.new()
	title.text = text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.52, 0.83, 1.0, 1.0))
	return title


func _make_button(text: String, minimum_size: Vector2) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = minimum_size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.83, 0.9, 1.0, 1.0))
	button.add_theme_color_override("font_hover_color", Color(0.96, 0.99, 1.0, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.035, 0.055, 0.095, 1.0))
	button.add_theme_stylebox_override(
		"normal",
		_make_button_style(Color(0.09, 0.115, 0.2, 0.96), Color(0.25, 0.34, 0.53, 1.0))
	)
	button.add_theme_stylebox_override(
		"hover",
		_make_button_style(Color(0.14, 0.2, 0.32, 1.0), Color(0.37, 0.68, 0.91, 1.0))
	)
	button.add_theme_stylebox_override(
		"pressed",
		_make_button_style(Color(0.35, 0.78, 0.92, 1.0), Color(0.56, 0.91, 1.0, 1.0))
	)
	return button


func _make_button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12.0
	style.content_margin_top = 7.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 7.0
	return style


func _set_anchor_rect(
	control: Control,
	horizontal_anchor: float,
	vertical_anchor: float,
	left: float,
	top: float,
	right: float,
	bottom: float
) -> void:
	control.anchor_left = horizontal_anchor
	control.anchor_right = horizontal_anchor
	control.anchor_top = vertical_anchor
	control.anchor_bottom = vertical_anchor
	control.offset_left = left
	control.offset_top = top
	control.offset_right = right
	control.offset_bottom = bottom


func _bind_hold(button: Button, action: String) -> void:
	button.button_down.connect(func() -> void: _set_touch_action(action, true))
	button.button_up.connect(func() -> void: _set_touch_action(action, false))


func _set_touch_action(action: String, value: bool) -> void:
	match action:
		"left":
			left_pressed = value
		"right":
			right_pressed = value
		"jump":
			jump_pressed = value


func _reset_touch() -> void:
	left_pressed = false
	right_pressed = false
	jump_pressed = false


func _set_touch_visible(value: bool) -> void:
	for button: Button in _touch_buttons:
		button.visible = value


func _set_record_ui_visible(value: bool) -> void:
	if is_instance_valid(_record_progress):
		_record_progress.visible = value
	if is_instance_valid(_record_timer_label):
		_record_timer_label.visible = value


func _set_game_buttons_visible(value: bool) -> void:
	for button: Button in _game_buttons:
		button.visible = value
