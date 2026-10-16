class_name GameVisuals
extends RefCounted

static var _radial_texture: Texture2D


static func create_light(
	parent: Node2D,
	color: Color,
	energy: float,
	texture_scale: float
) -> PointLight2D:
	if _radial_texture == null:
		_radial_texture = _create_radial_texture()

	var light: PointLight2D = PointLight2D.new()
	light.texture = _radial_texture
	light.color = color
	light.energy = energy
	light.texture_scale = texture_scale
	light.blend_mode = Light2D.BLEND_MODE_ADD
	light.shadow_enabled = false
	parent.add_child(light)
	return light


static func spawn_ring(
	parent: Node2D,
	local_position: Vector2,
	color: Color,
	start_radius: float = 8.0,
	duration: float = 0.28
) -> void:
	var effect: Node2D = Node2D.new()
	effect.position = local_position
	parent.add_child(effect)

	var ring: Line2D = Line2D.new()
	var points: PackedVector2Array = []
	for point_index: int in range(25):
		var angle: float = TAU * float(point_index) / 24.0
		points.append(Vector2(cos(angle) * start_radius, sin(angle) * start_radius))
	ring.points = points
	ring.closed = true
	ring.width = 2.0
	ring.default_color = color
	ring.antialiased = true
	effect.add_child(ring)

	var tween: Tween = effect.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(2.4, 2.4), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "modulate:a", 0.0, duration)
	tween.chain().tween_callback(effect.queue_free)


static func _create_radial_texture() -> Texture2D:
	const TEXTURE_SIZE: int = 96
	var image: Image = Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	var center: float = float(TEXTURE_SIZE - 1) * 0.5
	var radius: float = center
	for y: int in range(TEXTURE_SIZE):
		for x: int in range(TEXTURE_SIZE):
			var distance: float = Vector2(float(x) - center, float(y) - center).length() / radius
			var falloff: float = maxf(1.0 - distance, 0.0)
			var alpha: float = falloff * falloff
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(image)
