## HabitatItem.gd
## Attach to the root StaticBody2D of the HabitatItem scene.
## Initialise by calling setup(def, index, x) after adding to the scene.
extends StaticBody2D

# ── Properties ────────────────────────────────────────────────────────────────

## The item definition for this instance
var definition: HabitatItemDefinition = null

## Index into GameState.placed_items (used by DragHandler to save position)
var item_index: int = -1

# ── Internal ──────────────────────────────────────────────────────────────────
var _sprite: Sprite2D
var _anim_sprite: AnimatedSprite2D
var _drag_handler: Node

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_sprite       = $Sprite
	_anim_sprite  = get_node_or_null("AnimSprite")
	_drag_handler = $DragHandler
	_drag_handler.drag_ended.connect(func(_x): GameState.save_game())

## Call immediately after instancing.
func setup(def: HabitatItemDefinition, index: int, x: float) -> void:
	definition = def
	item_index = index
	z_index    = def.z_layer

	if def.animated_frames != null and _anim_sprite != null:
		_anim_sprite.sprite_frames = def.animated_frames
		_anim_sprite.play("default")
		_sprite.visible = false
	elif def.texture != null:
		_sprite.texture = def.texture
		if _anim_sprite: _anim_sprite.visible = false
	else:
		push_warning("HabitatItem.setup: definition '%s' has no texture or frames." % def.id)

	# Position — Y is always ground level (same as animals)
	var ground_y := _drag_handler.ground_y
	global_position = Vector2(x, ground_y)

	# Set drag bounds
	var strip_w := float(DisplayServer.window_get_size().x)
	_drag_handler.bounds_min_x = 0.0
	_drag_handler.bounds_max_x = strip_w

# ── Context menu (right-click to remove) ──────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if _is_mouse_over():
			_remove_self()

func _is_mouse_over() -> bool:
	var mouse := get_global_mouse_position()
	if definition == null:
		return false
	var tex_size := Vector2(definition.texture.get_size()) if definition.texture else Vector2(32, 32)
	return Rect2(global_position - tex_size * 0.5, tex_size).has_point(mouse)

func _remove_self() -> void:
	GameState.remove_item(item_index)
	queue_free()
