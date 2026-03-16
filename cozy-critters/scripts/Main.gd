## Main.gd
## Attach to the root Node of Main.tscn.
## Wires together WindowManager, World, HUD, ShopPanel, CollectionLog.
## Also handles the global hotkey for click-through toggle.
extends Node

# ── Node refs (assign in inspector or via $path) ──────────────────────────────
@onready var window_manager:  Node    = $WindowManager
@onready var strip_viewport:  SubViewportContainer = $StripViewport
@onready var hud:             Control = %HUD
@onready var shop_panel:      Control = %ShopPanel
@onready var collection_log:  Control = %CollectionLog

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	# Give WindowManager a reference to the viewport container for resize tweens
	window_manager._viewport_container = strip_viewport

	# Wire HUD references
	hud.shop_panel     = shop_panel
	hud.collection_log = collection_log
	hud.window_manager = window_manager

	# Hide panels at startup
	shop_panel.visible      = false
	collection_log.visible  = false

	# Connect passthrough status indicator if HUD has one
	window_manager.passthrough_changed.connect(_on_passthrough_changed)

	print("Cozy Critters ready. Strip width: %d" % DisplayServer.window_get_size().x)

# ── Global hotkeys ────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# Ctrl + Shift + C → toggle click-through
		if event.keycode == KEY_C and event.ctrl_pressed and event.shift_pressed:
			window_manager.toggle_passthrough()
			get_viewport().set_input_as_handled()

# ── Passthrough feedback ──────────────────────────────────────────────────────
## When passthrough is on, we dim the strip slightly so the user knows
## the app is in "hands-off" mode. Connect to a HUD label or colour rect.
func _on_passthrough_changed(is_passthrough: bool) -> void:
	# Optional: tint the strip viewport to signal passthrough state
	if strip_viewport:
		strip_viewport.modulate.a = 0.4 if is_passthrough else 1.0

# ── Application focus / quit ──────────────────────────────────────────────────

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		GameState.save_game()
		get_tree().quit()
