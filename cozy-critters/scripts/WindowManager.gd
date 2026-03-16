## WindowManager.gd
extends Node

const WINDOW_HEIGHT: int     = 500
const STRIP_HEIGHT_FULL: int = 150
const STRIP_HEIGHT_MIN: int  = 55
const TWEEN_DURATION: float  = 0.3

signal strip_toggled(is_minimised: bool)
signal passthrough_changed(is_passthrough: bool)

var is_minimised: bool   = false
var is_passthrough: bool = false

var _viewport_container: SubViewportContainer = null
var _screen_size: Vector2i
var _tween: Tween = null

func _ready() -> void:
	_screen_size = DisplayServer.screen_get_size()
	_apply_window_flags()
	# Set window to fixed 500px tall, anchored to bottom of screen. Never changes.
	DisplayServer.window_set_size(Vector2i(_screen_size.x, WINDOW_HEIGHT))
	DisplayServer.window_set_position(Vector2i(0, _screen_size.y - WINDOW_HEIGHT))

func _apply_window_flags() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_mouse_passthrough([])

# ── Minimise — animates StripViewport only, window stays 500px ────────────────

func toggle_minimise() -> void:
	is_minimised = !is_minimised
	var target_h := float(STRIP_HEIGHT_MIN if is_minimised else STRIP_HEIGHT_FULL)
	var from_h   := _viewport_container.size.y if _viewport_container else float(STRIP_HEIGHT_FULL)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_QUART)
	_tween.tween_method(_set_strip_height, from_h, target_h, TWEEN_DURATION)
	_tween.tween_callback(func(): strip_toggled.emit(is_minimised))

func _set_strip_height(h: float) -> void:
	if _viewport_container:
		_viewport_container.custom_minimum_size.y = h
		_viewport_container.size.y = h

# ── Passthrough ───────────────────────────────────────────────────────────────

func toggle_passthrough() -> void:
	is_passthrough = !is_passthrough
	_apply_passthrough()
	passthrough_changed.emit(is_passthrough)

func _apply_passthrough() -> void:
	if is_passthrough:
		var sz := DisplayServer.window_get_size()
		DisplayServer.window_set_mouse_passthrough(PackedVector2Array([
			Vector2(0, 0), Vector2(sz.x, 0),
			Vector2(sz.x, sz.y), Vector2(0, sz.y),
		]))
	else:
		DisplayServer.window_set_mouse_passthrough([])
