## AnimalInstance.gd
## Initialise by calling setup(def, uid, x, is_helper) after adding to the scene.
class_name AnimalInstance
extends CharacterBody2D

# ── Properties ────────────────────────────────────────────────────────────────

## The species definition for this instance (set via setup())
var definition: AnimalDefinition = null

## Unique instance ID matching the entry in GameState.placed_animals
var instance_uid: String = ""

## Whether this animal is currently generating passive Acorn income
var is_helper: bool = false:
	set(v):
		is_helper = v
		_update_helper_icon()

# ── Internal node refs (populated in _ready) ──────────────────────────────────
var _sprite: AnimatedSprite2D
var _helper_icon: Sprite2D
var _drag_handler: Node  # DragHandler

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("animals")
	_sprite       = $Sprite
	_helper_icon  = $HelperIcon
	_drag_handler = $DragHandler
	_update_helper_icon()

## Call this immediately after instancing the scene.
## def:       AnimalDefinition resource
## uid:       unique instance string from GameState
## start_x:   initial X position on the strip
## helper:    whether it starts as a Helper
func setup(def: AnimalDefinition, uid: String, start_x: float, helper: bool = false) -> void:
	definition   = def
	instance_uid = uid
	is_helper    = helper

	# Build SpriteFrames from the definition's spritesheet + AnimData entries
	_build_sprite_frames()

	# Set DragHandler bounds from the strip width
	var strip_w := float(DisplayServer.window_get_size().x)
	var margin  := float(def.frame_size.x) * 0.5
	_drag_handler.bounds_min_x = margin
	_drag_handler.bounds_max_x = strip_w - margin

	# Position
	global_position = Vector2(start_x, _drag_handler.ground_y)

	# Connect drag end to save
	_drag_handler.drag_ended.connect(func(_x): GameState.save_game())

	# Start in idle
	$StateMachine.transition(AnimalStateMachine.State.IDLE)

# ── Sprite setup ──────────────────────────────────────────────────────────────

func _build_sprite_frames() -> void:
	if definition == null or definition.spritesheet == null:
		push_warning("AnimalInstance._build_sprite_frames: no spritesheet on definition")
		return

	var frames := SpriteFrames.new()
	var tex    := definition.spritesheet
	var fs     := definition.frame_size
	var cols   := int(tex.get_width())  / fs.x

	for anim_name in definition.animations:
		var anim_data: AnimData = definition.animations[anim_name]
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, anim_data.looping)
		frames.set_animation_speed(anim_name, anim_data.fps)

		for i in range(anim_data.frame_count):
			var frame_index := anim_data.first_frame + i
			var col := frame_index % cols
			var row := frame_index / cols
			var region := Rect2(
				col * fs.x, row * fs.y,
				fs.x,        fs.y
			)
			var atlas := AtlasTexture.new()
			atlas.atlas  = tex
			atlas.region = region
			frames.add_frame(anim_name, atlas)

	_sprite.sprite_frames = frames
	_sprite.play("idle")

# ── Helper icon ───────────────────────────────────────────────────────────────

func _update_helper_icon() -> void:
	if _helper_icon:
		_helper_icon.visible = is_helper

# ── Context menu (right-click) ────────────────────────────────────────────────
## Show a minimal popup: "Set as Helper" / "Remove Helper" + "Send Home" (remove from strip)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if _is_mouse_over():
			_show_context_menu()

func _is_mouse_over() -> bool:
	var mouse := get_global_mouse_position()
	var half  := Vector2(definition.frame_size) * 0.5 if definition else Vector2(16, 16)
	return Rect2(global_position - half, half * 2.0).has_point(mouse)

func _show_context_menu() -> void:
	## Emit a signal upward so World/UI layer can display a context popup.
	## Keeping UI construction out of this script.
	get_parent().emit_signal("animal_context_requested", self)
