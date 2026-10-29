extends Control
## Un focolaio sulla mappa: emblema, bagliore che pulsa, fumo e scintille che crescono con l'intensità,
## pallini e nome sotto. Il centro dell'emblema sta nell'origine del nodo.

signal tapped(outbreak_id: int)

const EMBLEM_SIZE := 116.0
const CAPTION_WIDTH := 210.0

var outbreak: Outbreak
var cfg: GameConfig


func setup(c: GameConfig, o: Outbreak) -> void:
	cfg = c
	outbreak = o


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var heat := float(outbreak.intensity) / 5.0

	var glow := TextureRect.new()
	glow.texture = Art.glow_texture()
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow_size := EMBLEM_SIZE * (1.5 + 0.5 * heat)
	glow.size = Vector2(glow_size, glow_size)
	glow.position = -glow.size / 2
	glow.pivot_offset = glow.size / 2
	glow.modulate = Color(1, 0.5, 0.15, 0.45 + 0.45 * heat)
	glow.material = _additive()
	add_child(glow)
	# Più è intenso, più il bagliore pulsa in fretta.
	var period := 1.8 - 0.25 * outbreak.intensity
	var pulse := glow.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	pulse.tween_property(glow, "scale", Vector2.ONE * 1.12, period / 2)
	pulse.tween_property(glow, "scale", Vector2.ONE * 0.92, period / 2)

	add_child(_smoke(heat))

	var button := TextureButton.new()
	button.texture_normal = Art.emblem(outbreak.type_id)
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.size = Vector2(EMBLEM_SIZE, EMBLEM_SIZE)
	button.position = -button.size / 2
	button.pressed.connect(func(): tapped.emit(outbreak.id))
	add_child(button)
	add_child(_flames(heat))

	var caption := UiKit.vbox(4)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.position = Vector2(-CAPTION_WIDTH / 2, EMBLEM_SIZE / 2 - 6)
	caption.size = Vector2(CAPTION_WIDTH, 0)
	caption.add_child(Art.dots(outbreak.intensity))
	caption.add_child(Art.shadowed_label(cfg.type_by_id(outbreak.type_id).get("name", outbreak.type_id), UiKit.FONT_SMALL - 2, UiKit.INK))
	if outbreak.revealed:
		var info := "%s · %s" % [UiKit.NATURE_SHORT[outbreak.nature], UiKit.APPROACH_NAMES[outbreak.weakness]]
		caption.add_child(Art.shadowed_label(info, UiKit.FONT_SMALL - 4, UiKit.GOLD))
	add_child(caption)


## Scintille che salgono dall'emblema: più numerose e alte con l'intensità.
func _flames(heat: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = 6 + int(22 * heat)
	p.lifetime = 1.1 + 0.6 * heat
	p.preprocess = p.lifetime
	p.position = Vector2(0, -EMBLEM_SIZE * 0.3)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(EMBLEM_SIZE * 0.3, 6)
	p.direction = Vector2.UP
	p.spread = 25
	p.gravity = Vector2(0, -40 - 60 * heat)
	p.initial_velocity_min = 20
	p.initial_velocity_max = 50 + 40 * heat
	p.texture = Art.glow_texture()
	p.material = _additive()
	p.scale_amount_min = 0.08
	p.scale_amount_max = 0.14 + 0.08 * heat
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 0.85, 0.45, 0.9))
	ramp.set_color(1, Color(0.8, 0.2, 0.05, 0))
	p.color_ramp = ramp
	return p


## Fumo scuro che sale lento dietro l'emblema e si allarga svanendo.
func _smoke(heat: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	# Sotto tutti gli emblemi e le scritte (anche dei focolai vicini), sopra la città.
	p.z_index = -1
	p.amount = 4 + int(8 * heat)
	p.lifetime = 2.4
	p.preprocess = p.lifetime
	p.position = Vector2(0, -EMBLEM_SIZE * 0.2)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(EMBLEM_SIZE * 0.2, 4)
	p.direction = Vector2.UP
	p.spread = 12
	p.gravity = Vector2(6, -8)
	p.initial_velocity_min = 25
	p.initial_velocity_max = 40 + 20 * heat
	p.texture = Art.glow_texture()
	p.scale_amount_min = 0.5
	p.scale_amount_max = 0.8 + 0.4 * heat
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.12, 0.09, 0.08, 0.0))
	ramp.set_color(1, Color(0.2, 0.17, 0.15, 0.0))
	ramp.add_point(0.2, Color(0.1, 0.08, 0.07, 0.6 + 0.25 * heat))
	p.color_ramp = ramp
	return p


func _additive() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m
