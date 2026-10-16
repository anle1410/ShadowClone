extends Node2D

const Visuals = preload("res://scripts/game_visuals.gd")

@export_enum("Sky", "Distant forest", "Midground", "Foreground and mist")
var layer_index: int = 0

var _mote_time: float = 0.0
var _mote_refresh: float = 0.0


func _ready() -> void:
	if layer_index == 0:
		var moonlight: PointLight2D = Visuals.create_light(
			self,
			Color(0.5, 0.63, 1.0, 1.0),
			0.35,
			1.8
		)
		moonlight.position = Vector2(1005.0, 170.0)


func _process(delta: float) -> void:
	if layer_index != 0 and layer_index != 3:
		return
	_mote_time += delta
	_mote_refresh += delta
	if _mote_refresh >= 0.12:
		_mote_refresh = 0.0
		queue_redraw()


func _draw() -> void:
	match layer_index:
		0:
			_draw_sky()
		3:
			_draw_fog_overlay()


func _draw_sky() -> void:
	for band: int in range(216):
		var band_y: float = -720.0 + float(band) * 10.0
		var blend: float = clampf((band_y + 180.0) / 900.0, 0.0, 1.0)
		var sky_color: Color = Color(0.018, 0.027, 0.06, 1.0).lerp(
			Color(0.095, 0.067, 0.15, 1.0),
			blend
		)
		draw_rect(Rect2(0.0, band_y, 1280.0, 11.0), sky_color)

	var aurora_points: PackedVector2Array = []
	for point_index: int in range(33):
		var x: float = float(point_index) * 40.0
		var y: float = 212.0 + sin(float(point_index) / 32.0 * TAU + _mote_time * 0.035) * 19.0
		aurora_points.append(Vector2(x, y))
	draw_polyline(aurora_points, Color(0.12, 0.48, 0.72, 0.035), 46.0, false)
	draw_polyline(aurora_points, Color(0.16, 0.55, 0.78, 0.06), 22.0, false)
	draw_polyline(aurora_points, Color(0.24, 0.72, 0.82, 0.095), 2.0, false)

	var cloud_color: Color = Color(0.2, 0.27, 0.45, 0.12)
	for cloud_index: int in range(5):
		var cloud_x: float = float(cloud_index) * 310.0 - 120.0
		var cloud_y: float = 278.0 + sin(float(cloud_index) * 2.1) * 26.0
		draw_line(
			Vector2(cloud_x, cloud_y),
			Vector2(cloud_x + 220.0, cloud_y - 12.0),
			cloud_color,
			19.0,
			true
		)
		draw_line(
			Vector2(cloud_x + 46.0, cloud_y + 12.0),
			Vector2(cloud_x + 180.0, cloud_y + 4.0),
			Color(0.28, 0.34, 0.55, 0.07),
			8.0,
			true
		)

	for index: int in range(54):
		var x: float = float((index * 173 + 41) % 1240) + 20.0
		var y: float = float((index * 97 + 23) % 430) + 20.0
		var is_bright: bool = index % 6 == 0
		var radius: float = 1.35 if is_bright else 0.75
		var alpha: float = 0.52 if is_bright else 0.2
		draw_circle(Vector2(x, y), radius, Color(0.63, 0.78, 1.0, alpha))

	var moon_center: Vector2 = Vector2(1005.0, 170.0)
	draw_circle(moon_center, 118.0, Color(0.18, 0.34, 0.7, 0.025))
	draw_circle(moon_center, 97.0, Color(0.27, 0.44, 0.82, 0.045))
	draw_circle(moon_center, 78.0, Color(0.36, 0.54, 0.9, 0.07))
	draw_arc(moon_center, 85.0, -0.9, 2.6, 48, Color(0.52, 0.67, 0.94, 0.17), 1.0, true)
	draw_circle(moon_center, 62.0, Color(0.49, 0.63, 0.86, 0.12))
	draw_circle(moon_center, 48.0, Color(0.67, 0.76, 0.91, 0.88))
	draw_circle(moon_center + Vector2(-8.0, -7.0), 41.0, Color(0.8, 0.85, 0.96, 0.96))
	draw_circle(moon_center + Vector2(15.0, 8.0), 7.0, Color(0.52, 0.63, 0.82, 0.26))
	draw_circle(moon_center + Vector2(-18.0, 17.0), 4.0, Color(0.52, 0.63, 0.82, 0.22))
	draw_circle(moon_center + Vector2(12.0, -20.0), 3.0, Color(0.55, 0.66, 0.84, 0.2))
	draw_arc(moon_center + Vector2(-7.0, 5.0), 33.0, 0.2, 1.65, 32, Color(0.42, 0.54, 0.75, 0.18), 1.2, true)

	for mote_index: int in range(16):
		var x: float = fposmod(float(mote_index * 139) + _mote_time * float(7 + mote_index % 4), 1280.0)
		var y: float = 360.0 + sin(_mote_time * 0.42 + float(mote_index) * 1.9) * 70.0
		var alpha: float = 0.18 + (sin(_mote_time * 1.4 + float(mote_index)) + 1.0) * 0.08
		var radius: float = 1.0 if mote_index % 4 != 0 else 1.6
		draw_circle(Vector2(x, y), radius, Color(0.47, 0.85, 0.97, alpha))


func _draw_fog_overlay() -> void:
	for band: int in range(5):
		var drift: float = fposmod(_mote_time * (3.0 + float(band)) + float(band) * 257.0, 1500.0) - 160.0
		var y: float = 420.0 + float(band) * 28.0
		var alpha: float = 0.018 + float(band % 2) * 0.008
		draw_line(
			Vector2(drift, y),
			Vector2(drift + 420.0, y + sin(_mote_time * 0.12 + float(band)) * 5.0),
			Color(0.47, 0.62, 0.83, alpha),
			18.0 + float(band % 3) * 5.0,
			true
		)


func _draw_mountains() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, 396.0), Vector2(123.0, 276.0),
		Vector2(232.0, 344.0), Vector2(379.0, 239.0), Vector2(531.0, 363.0),
		Vector2(680.0, 272.0), Vector2(844.0, 371.0), Vector2(1005.0, 258.0),
		Vector2(1163.0, 365.0), Vector2(1280.0, 396.0), Vector2(1280.0, 720.0),
		Vector2(0.0, 720.0)
	]), Color(0.058, 0.071, 0.13, 1.0))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, 496.0), Vector2(153.0, 354.0),
		Vector2(286.0, 424.0), Vector2(452.0, 322.0), Vector2(600.0, 442.0),
		Vector2(758.0, 349.0), Vector2(919.0, 434.0), Vector2(1076.0, 328.0),
		Vector2(1280.0, 496.0), Vector2(1280.0, 720.0), Vector2(0.0, 720.0)
	]), Color(0.087, 0.092, 0.16, 1.0))
	draw_polyline(PackedVector2Array([
		Vector2(0.0, 396.0), Vector2(123.0, 276.0), Vector2(232.0, 344.0),
		Vector2(379.0, 239.0), Vector2(531.0, 363.0), Vector2(680.0, 272.0),
		Vector2(844.0, 371.0), Vector2(1005.0, 258.0), Vector2(1163.0, 365.0),
		Vector2(1280.0, 396.0)
	]), Color(0.31, 0.42, 0.64, 0.22), 2.0, false)
	draw_polyline(PackedVector2Array([
		Vector2(0.0, 496.0), Vector2(153.0, 354.0), Vector2(286.0, 424.0),
		Vector2(452.0, 322.0), Vector2(600.0, 442.0), Vector2(758.0, 349.0),
		Vector2(919.0, 434.0), Vector2(1076.0, 328.0), Vector2(1280.0, 496.0)
	]), Color(0.24, 0.35, 0.54, 0.16), 1.4, false)

	for peak_index: int in range(8):
		var peak_x: float = 115.0 + float(peak_index) * 154.0
		var peak_y: float = 270.0 + float((peak_index * 67) % 120)
		draw_line(
			Vector2(peak_x, peak_y),
			Vector2(peak_x + 48.0, peak_y + 43.0),
			Color(0.56, 0.67, 0.86, 0.12),
			1.2,
			true
		)
		draw_line(
			Vector2(peak_x + 48.0, peak_y + 43.0),
			Vector2(peak_x + 61.0, peak_y + 60.0),
			Color(0.56, 0.67, 0.86, 0.07),
			1.0,
			true
		)

	for band: int in range(5):
		var drift: float = fposmod(_mote_time * (3.0 + float(band)) + float(band) * 257.0, 1500.0) - 160.0
		var y: float = 414.0 + float(band) * 24.0
		var alpha: float = 0.018 + float(band % 2) * 0.008
		draw_line(
			Vector2(drift, y),
			Vector2(drift + 420.0, y + sin(_mote_time * 0.12 + float(band)) * 5.0),
			Color(0.47, 0.62, 0.83, alpha),
			18.0 + float(band % 3) * 5.0,
			true
		)


func _draw_ruins() -> void:
	var stone: Color = Color(0.045, 0.058, 0.11, 1.0)
	var stone_lit: Color = Color(0.19, 0.24, 0.39, 0.62)
	var rune: Color = Color(0.32, 0.7, 0.88, 0.42)

	draw_rect(Rect2(112.0, 367.0, 28.0, 221.0), stone)
	draw_colored_polygon(PackedVector2Array([
		Vector2(99.0, 374.0), Vector2(99.0, 360.0), Vector2(113.0, 355.0),
		Vector2(144.0, 361.0), Vector2(153.0, 374.0)
	]), stone)
	draw_line(Vector2(116.0, 378.0), Vector2(116.0, 575.0), stone_lit, 2.0)
	draw_rect(Rect2(127.0, 396.0, 9.0, 30.0), rune)
	draw_rect(Rect2(130.0, 404.0, 3.0, 16.0), Color(0.7, 0.89, 1.0, 0.52))
	draw_line(Vector2(117.0, 445.0), Vector2(123.0, 451.0), Color(0.025, 0.032, 0.065, 0.9), 2.0)
	draw_line(Vector2(123.0, 451.0), Vector2(119.0, 459.0), Color(0.025, 0.032, 0.065, 0.9), 1.2)

	draw_rect(Rect2(177.0, 434.0, 21.0, 151.0), stone)
	draw_colored_polygon(PackedVector2Array([
		Vector2(168.0, 441.0), Vector2(168.0, 428.0), Vector2(180.0, 421.0),
		Vector2(203.0, 427.0), Vector2(209.0, 441.0)
	]), stone)
	draw_line(Vector2(190.0, 440.0), Vector2(190.0, 572.0), stone_lit, 1.5)

	draw_colored_polygon(PackedVector2Array([
		Vector2(350.0, 581.0), Vector2(350.0, 469.0), Vector2(358.0, 458.0),
		Vector2(366.0, 462.0), Vector2(366.0, 581.0)
	]), Color(0.052, 0.065, 0.12, 0.94))
	draw_colored_polygon(PackedVector2Array([
		Vector2(406.0, 581.0), Vector2(406.0, 478.0), Vector2(414.0, 470.0),
		Vector2(423.0, 475.0), Vector2(423.0, 581.0)
	]), Color(0.052, 0.065, 0.12, 0.94))
	draw_arc(Vector2(386.0, 493.0), 28.0, PI, TAU, 18, Color(0.17, 0.22, 0.36, 0.62), 4.0, true)
	draw_line(Vector2(347.0, 462.0), Vector2(358.0, 455.0), stone_lit, 2.0)
	draw_line(Vector2(411.0, 472.0), Vector2(423.0, 468.0), stone_lit, 2.0)
	draw_line(Vector2(357.0, 494.0), Vector2(357.0, 524.0), rune, 1.4)
	draw_line(Vector2(416.0, 506.0), Vector2(416.0, 531.0), rune, 1.2)

	draw_rect(Rect2(882.0, 395.0, 28.0, 193.0), stone)
	draw_colored_polygon(PackedVector2Array([
		Vector2(871.0, 403.0), Vector2(871.0, 390.0), Vector2(884.0, 382.0),
		Vector2(913.0, 389.0), Vector2(921.0, 403.0)
	]), stone)
	draw_line(Vector2(901.0, 402.0), Vector2(901.0, 575.0), stone_lit, 1.5)
	draw_rect(Rect2(951.0, 449.0, 20.0, 136.0), stone)
	draw_arc(Vector2(899.0, 404.0), 74.0, PI, TAU, 24, stone_lit, 4.0)
	draw_arc(Vector2(899.0, 404.0), 66.0, PI, TAU, 24, Color(0.09, 0.12, 0.21, 0.9), 7.0)
	draw_line(Vector2(899.0, 343.0), Vector2(899.0, 366.0), rune, 2.0)
	draw_circle(Vector2(899.0, 338.0), 4.0, Color(0.45, 0.83, 1.0, 0.62))
	draw_line(Vector2(884.0, 431.0), Vector2(890.0, 438.0), Color(0.025, 0.032, 0.065, 0.9), 1.8)
	draw_line(Vector2(890.0, 438.0), Vector2(886.0, 448.0), Color(0.025, 0.032, 0.065, 0.9), 1.2)
	draw_arc(Vector2(899.0, 404.0), 58.0, PI + 0.15, PI + 0.75, 10, rune, 1.2, true)
	draw_arc(Vector2(899.0, 404.0), 58.0, TAU - 0.75, TAU - 0.15, 10, rune, 1.2, true)

	draw_arc(Vector2(640.0, 526.0), 91.0, PI + 0.12, TAU - 0.12, 32, Color(0.12, 0.16, 0.28, 0.78), 14.0)
	draw_arc(Vector2(640.0, 526.0), 98.0, PI + 0.32, TAU - 0.3, 28, Color(0.28, 0.36, 0.53, 0.36), 3.0)
	draw_line(Vector2(549.0, 526.0), Vector2(549.0, 581.0), stone, 13.0)
	draw_line(Vector2(731.0, 526.0), Vector2(731.0, 581.0), stone, 13.0)
	draw_line(Vector2(637.0, 439.0), Vector2(643.0, 475.0), rune, 2.0)
	draw_circle(Vector2(640.0, 432.0), 4.0, Color(0.45, 0.83, 1.0, 0.55))
	draw_line(Vector2(575.0, 536.0), Vector2(585.0, 542.0), stone_lit, 2.0)
	draw_line(Vector2(696.0, 550.0), Vector2(706.0, 544.0), stone_lit, 2.0)

	draw_rect(Rect2(1081.0, 334.0, 42.0, 255.0), stone)
	draw_colored_polygon(PackedVector2Array([
		Vector2(1071.0, 343.0), Vector2(1071.0, 327.0), Vector2(1090.0, 317.0),
		Vector2(1129.0, 326.0), Vector2(1135.0, 343.0)
	]), stone)
	draw_line(Vector2(1091.0, 350.0), Vector2(1091.0, 574.0), stone_lit, 2.0)
	draw_rect(Rect2(1100.0, 367.0, 6.0, 62.0), rune)
	draw_line(Vector2(1085.0, 432.0), Vector2(1091.0, 438.0), Color(0.025, 0.032, 0.065, 0.9), 1.6)
	draw_line(Vector2(1091.0, 438.0), Vector2(1087.0, 447.0), Color(0.025, 0.032, 0.065, 0.9), 1.1)
	draw_line(Vector2(1101.0, 456.0), Vector2(1106.0, 463.0), Color(0.025, 0.032, 0.065, 0.9), 1.0)

	for fog_band: int in range(4):
		var drift: float = fposmod(_mote_time * (5.0 + float(fog_band)) + float(fog_band) * 391.0, 1600.0) - 160.0
		var fog_y: float = 499.0 + float(fog_band) * 25.0
		draw_line(
			Vector2(drift, fog_y),
			Vector2(drift + 500.0, fog_y - 5.0),
			Color(0.44, 0.58, 0.82, 0.025 + float(fog_band % 2) * 0.009),
			15.0 + float(fog_band % 2) * 5.0,
			true
		)


func _draw_near_silhouettes() -> void:
	var branch: Color = Color(0.025, 0.032, 0.065, 0.82)
	var edge: Color = Color(0.19, 0.24, 0.38, 0.44)

	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, 574.0), Vector2(0.0, 528.0), Vector2(24.0, 519.0),
		Vector2(37.0, 535.0), Vector2(55.0, 527.0), Vector2(72.0, 542.0),
		Vector2(91.0, 536.0), Vector2(118.0, 555.0), Vector2(145.0, 560.0),
		Vector2(145.0, 588.0)
	]), branch)
	draw_line(Vector2(31.0, 570.0), Vector2(20.0, 540.0), edge, 2.0)
	draw_line(Vector2(34.0, 551.0), Vector2(52.0, 537.0), edge, 1.5)
	draw_line(Vector2(67.0, 562.0), Vector2(79.0, 543.0), edge, 1.5)
	draw_line(Vector2(31.0, 557.0), Vector2(14.0, 548.0), edge, 1.2)
	draw_line(Vector2(72.0, 557.0), Vector2(94.0, 551.0), edge, 1.2)

	draw_colored_polygon(PackedVector2Array([
		Vector2(1137.0, 588.0), Vector2(1160.0, 558.0), Vector2(1180.0, 549.0),
		Vector2(1197.0, 531.0), Vector2(1212.0, 539.0), Vector2(1226.0, 520.0),
		Vector2(1240.0, 537.0), Vector2(1260.0, 528.0), Vector2(1280.0, 542.0),
		Vector2(1280.0, 588.0)
	]), branch)
	draw_line(Vector2(1204.0, 566.0), Vector2(1190.0, 542.0), edge, 2.0)
	draw_line(Vector2(1200.0, 550.0), Vector2(1221.0, 536.0), edge, 1.5)
	draw_line(Vector2(1241.0, 558.0), Vector2(1255.0, 538.0), edge, 1.5)
	draw_line(Vector2(1200.0, 552.0), Vector2(1179.0, 546.0), edge, 1.2)
	draw_line(Vector2(1243.0, 552.0), Vector2(1265.0, 547.0), edge, 1.2)

	for band: int in range(6):
		var drift: float = fposmod(_mote_time * (2.0 + float(band)) + float(band) * 293.0, 1480.0) - 120.0
		var y: float = 407.0 + float(band) * 31.0
		var opacity: float = 0.025 - float(band) * 0.002
		draw_line(
			Vector2(drift, y),
			Vector2(drift + 360.0, y + 3.0),
			Color(0.43, 0.5, 0.72, opacity),
			16.0 + float(band % 2) * 6.0,
			true
		)
