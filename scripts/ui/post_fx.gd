class_name PostFX
extends CanvasLayer
## The watercolour filter laid over the 3D view (below all UI).

var rect: ColorRect
var mat: ShaderMaterial


func _ready() -> void:
	layer = 1
	rect = ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat = ShaderMaterial.new()
	mat.shader = preload("res://shaders/watercolor.gdshader")
	mat.set_shader_parameter("paper_tex", _paper_texture())
	rect.material = mat
	add_child(rect)
	get_viewport().size_changed.connect(_on_resize)
	_on_resize()


func _process(_delta: float) -> void:
	rect.visible = bool(Game.settings.get("painterly", true))


func _on_resize() -> void:
	var h := float(get_viewport().get_visible_rect().size.y)
	var real_h := float(DisplayServer.window_get_size().y) if DisplayServer.get_name() != "headless" else h
	mat.set_shader_parameter("radius", clampi(int(round(maxf(h, real_h) / 1080.0 * 3.0)), 2, 6))


func _paper_texture() -> Texture2D:
	var n := FastNoiseLite.new()
	n.seed = 8
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX
	n.frequency = 0.03
	n.fractal_octaves = 5
	var img := n.get_seamless_image(512, 512, false, false, 0.1, true)
	img.convert(Image.FORMAT_RGBA8)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
