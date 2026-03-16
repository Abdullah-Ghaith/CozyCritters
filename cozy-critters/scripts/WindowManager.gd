## WindowManager.gd
## Attach to a Node child of Main (created before anything draws).
## Positions the window as a transparent always-on-top strip at the bottom
## of the primary monitor, and manages click-through / minimise state.
##
## When a panel (shop/collection) opens, the window grows upward to reveal it.
## When all panels close, it shrinks back to the strip height.
extends Node
 
# ── Configuration ─────────────────────────────────────────────────────────────
 
## Height of the strip when fully expanded (pixels)
const STRIP_HEIGHT_FULL: int = 150
 
## Height of the strip when minimised (just a thin coloured bar)
const STRIP_HEIGHT_MIN: int = 55
 
## How tall the window becomes when a panel is open (strip + panel)
const PANEL_HEIGHT: int = 500
 
## How long the minimise/expand tween takes (seconds)
const TWEEN_DURATION: float = 0.25
 
# ── Signals ───────────────────────────────────────────────────────────────────
 
signal strip_toggled(is_minimised: bool)
signal passthrough_changed(is_passthrough: bool)
 
# ── State ─────────────────────────────────────────────────────────────────────
 
var is_minimised: bool = false
var is_passthrough: bool = false
 
## How many panels are currently open — window stays tall until this hits 0
var _open_panel_count: int = 0
 
# ── Internal ──────────────────────────────────────────────────────────────────
 
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
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_mouse_passthrough([])
 
func _position_window(height: int) -> void:
	var w := _screen_size.x
	DisplayServer.window_set_size(Vector2i(w, height))
	DisplayServer.window_set_position(Vector2i(0, _screen_size.y - height))
 
# ── Panel open / close ────────────────────────────────────────────────────────
 
## Call this when any panel (shop, collection) becomes visible.
func on_panel_opened() -> void:
	_open_panel_count += 1
	if _open_panel_count == 1:
		_animate_to_height(PANEL_HEIGHT)
 
## Call this when any panel becomes hidden.
func on_panel_closed() -> void:
	_open_panel_count = max(0, _open_panel_count - 1)
	if _open_panel_count == 0:
		var target := STRIP_HEIGHT_MIN if is_minimised else STRIP_HEIGHT_FULL
		_animate_to_height(target)
 
# ── Minimise / Expand ─────────────────────────────────────────────────────────
 
func toggle_minimise() -> void:
	is_minimised = !is_minimised
	# Only resize if no panels are open — panels take priority
	if _open_panel_count == 0:
		var target_h := STRIP_HEIGHT_MIN if is_minimised else STRIP_HEIGHT_FULL
		_animate_to_height(target_h)
	strip_toggled.emit(is_minimised)
 
func _animate_to_height(target_h: int) -> void:
	var from_h := DisplayServer.window_get_size().y
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_window_height, float(from_h), float(target_h), TWEEN_DURATION)
 
func _set_window_height(h: float) -> void:
	_position_window(int(h))
	if _viewport_container:
		_viewport_container.custom_minimum_size.y = min(h, STRIP_HEIGHT_FULL)
		_viewport_container.size.y = min(h, STRIP_HEIGHT_FULL)
 
# ── Click-Through ─────────────────────────────────────────────────────────────
 
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
		var poly := PackedVector2Array([
			Vector2(0, 0),
			Vector2(sz.x, 0),
			Vector2(sz.x, sz.y),
			Vector2(0, sz.y),
		])
		DisplayServer.window_set_mouse_passthrough(poly)
	else:
		DisplayServer.window_set_mouse_passthrough([])
