## CollectionLog.gd
## Attach to the CollectionLog Control node inside UILayer.
## Displays a grid of all animals — unlocked ones show their sprite and name,
## locked ones show a silhouette and their unlock_hint.
extends Control

# ── Exports ───────────────────────────────────────────────────────────────────
@export var log_card_scene: PackedScene   ## Assign a simple LogCard.tscn (or reuse ShopCard)

# ── Internal ──────────────────────────────────────────────────────────────────
@onready var grid:         GridContainer = $ScrollContainer/Grid
@onready var close_button: Button        = $CloseButton
@onready var count_label:  Label         = $CountLabel

# Rarity colours for border tints
const RARITY_COLOURS := {
	AnimalDefinition.Rarity.COMMON:   Color(0.75, 0.75, 0.75),
	AnimalDefinition.Rarity.UNCOMMON: Color(0.40, 0.85, 0.40),
	AnimalDefinition.Rarity.RARE:     Color(0.35, 0.55, 1.00),
	AnimalDefinition.Rarity.SECRET:   Color(0.85, 0.55, 0.95),
}

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	close_button.pressed.connect(func(): visible = false)
	visibility_changed.connect(_on_visibility_changed)
	GameState.animal_unlocked.connect(func(_id): if visible: _populate())

func _on_visibility_changed() -> void:
	if visible: _populate()

# ── Population ────────────────────────────────────────────────────────────────

func _populate() -> void:
	for child in grid.get_children():
		child.queue_free()

	var all_defs := AnimalRegistry.get_all()
	var unlocked_count := 0

	for def in all_defs:
		var is_unlocked := GameState.is_animal_unlocked(def.id)
		if is_unlocked:
			unlocked_count += 1
		_add_log_entry(def, is_unlocked)

	count_label.text = "%d / %d collected" % [unlocked_count, all_defs.size()]

func _add_log_entry(def: AnimalDefinition, is_unlocked: bool) -> void:
	## Build a simple card inline using a VBoxContainer.
	## Replace this with log_card_scene.instantiate() once you have a LogCard scene.
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(80, 96)

	var vbox := VBoxContainer.new()
	card.add_child(vbox)

	var tex_rect := TextureRect.new()
	tex_rect.custom_minimum_size = Vector2(64, 64)
	tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	if is_unlocked and def.spritesheet:
		tex_rect.texture = def.spritesheet
		tex_rect.modulate = Color.WHITE
	else:
		tex_rect.texture = def.spritesheet
		tex_rect.modulate = Color(0.1, 0.1, 0.1, 0.8)  # silhouette

	vbox.add_child(tex_rect)

	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if is_unlocked:
		label.text = def.display_name
	else:
		label.text = def.unlock_hint
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(label)

	# Rarity tint on the panel border
	if is_unlocked:
		var rarity_col: Color = RARITY_COLOURS.get(def.rarity, Color.WHITE)
		card.add_theme_stylebox_override("panel", _make_rarity_style(rarity_col))

	grid.add_child(card)

func _make_rarity_style(colour: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color          = Color(0.15, 0.15, 0.15, 0.9)
	style.border_color      = colour
	style.border_width_left   = 2
	style.border_width_right  = 2
	style.border_width_top    = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	return style
