## WindowManager.gd
## Attach to a Node child of Main (created before anything draws).
## Positions the window as a transparent always-on-top strip at the bottom
## of the primary monitor, and manages click-through / minimise state.
extends Node

# ── Configuration ─────────────────────────────────────────────────────────────

## Height of the strip when fully expanded (pixels)
const STRIP_HEIGHT_FULL: int = 150

## Height of the strip when minimised (just a thin coloured bar)
const STRIP_HEIGHT_MIN: int  = 24

## How long the minimise/expand tween takes (seconds)
const TWEEN_DURATION: float  = 0.25

# ── Signals ───────────────────────────────────────────────────────────────────

## Emitted after minimise/expand animation finishes. is_minimised = new state.
signal strip_toggled(is_minimised: bool)

## Emitted when click-through is toggled
signal passthrough_changed(is_passthrough: bool)

# ── State ─────────────────────────────────────────────────────────────────────

var is_minimised: bool    = false
var is_passthrough: bool  = false

# ── Internal ──────────────────────────────────────────────────────────────────

## Reference to StripViewportContainer — set this from Main.gd after the scene loads.
## WindowManager calls resize_viewport() on it during minimise/expand.
var _viewport_container: SubViewportContainer = null

var _screen_size: Vector2i
var _tween: Tween = null

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_screen_size = DisplayServer.screen_get_size()
	_apply_window_flags()
	_position_window(STRIP_HEIGHT_FULL)
	print("WindowManager: overlay ready at %s, strip height %dpx" % [
		DisplayServer.window_get_position(), STRIP_HEIGHT_FULL
	])

func _apply_window_flags() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP,   true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT,     true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,      true)
	# Start with click interaction enabled
	DisplayServer.window_set_mouse_passthrough([])

func _position_window(height: int) -> void:
	var w := _screen_size.x
	DisplayServer.window_set_size(Vector2i(w, height))
	DisplayServer.window_set_position(Vector2i(0, _screen_size.y - height))

# ── Minimise / Expand ─────────────────────────────────────────────────────────

## Toggle the strip between full height and minimised.
## Call this from HUD's minimise button.
func toggle_minimise() -> void:
	is_minimised = !is_minimised
	var target_h := STRIP_HEIGHT_MIN if is_minimised else STRIP_HEIGHT_FULL

	if _tween:
		_tween.kill()
	_tween = create_tween()

	# We animate a local variable and apply it each step
	var from_h := STRIP_HEIGHT_MIN if not is_minimised else STRIP_HEIGHT_FULL
	_tween.tween_method(_set_window_height, float(from_h), float(target_h), TWEEN_DURATION)
	_tween.tween_callback(func(): strip_toggled.emit(is_minimised))

func _set_window_height(h: float) -> void:
	var ih := int(h)
	_position_window(ih)
	if _viewport_container:
		_viewport_container.custom_minimum_size.y = h
		_viewport_container.size.y = h

# ── Click-Through ─────────────────────────────────────────────────────────────

## Toggle whether mouse input passes through the window to the desktop below.
## Bind to a hotkey (e.g. Ctrl+Shift+C) in Main.gd or to a tray icon menu item.
func toggle_passthrough() -> void:
	is_passthrough = !is_passthrough
	_apply_passthrough()
	passthrough_changed.emit(is_passthrough)

func set_passthrough(enabled: bool) -> void:
	is_passthrough = enabled
	_apply_passthrough()
	passthrough_changed.emit(is_passthrough)

func _apply_passthrough() -> void:
	if is_passthrough:
		var sz := DisplayServer.window_get_size()
		# Passing a polygon covering the whole window = full passthrough
		var poly := PackedVector2Array([
			Vector2(0,       0      ),
			Vector2(sz.x,    0      ),
			Vector2(sz.x,    sz.y   ),
			Vector2(0,       sz.y   ),
		])
		DisplayServer.window_set_mouse_passthrough(poly)
	else:
		# Empty array = no passthrough region = normal interaction
		DisplayServer.window_set_mouse_passthrough([])
