## HUD.gd
## Attach to the HUD Control node inside UILayer.
## Shows acorn count, shop button, collection button, and minimise toggle.
extends Control

# ── Internal node refs ────────────────────────────────────────────────────────
@onready var acorn_label: Label     = %AcornLabel
@onready var shop_button: Button    = %ShopButton
@onready var log_button:  Button    = %LogButton
@onready var min_button:  Button    = %MinimizeButton

# ── References (assign from Main.gd or inspector) ─────────────────────────────
@export var shop_panel:     Control = null
@export var collection_log: Control = null
@export var window_manager: Node    = null

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	GameState.acorns_changed.connect(_on_acorns_changed)
	_on_acorns_changed(GameState.acorns)  # populate immediately

	shop_button.pressed.connect(_on_shop_pressed)
	log_button.pressed.connect(_on_log_pressed)
	min_button.pressed.connect(_on_minimise_pressed)

	if window_manager:
		window_manager.strip_toggled.connect(_on_strip_toggled)

# ── Handlers ──────────────────────────────────────────────────────────────────

func _on_acorns_changed(new_total: int) -> void:
	acorn_label.text = _format_acorns(new_total)

func _on_shop_pressed() -> void:
	if shop_panel:
		shop_panel.visible = !shop_panel.visible

func _on_log_pressed() -> void:
	if collection_log:
		collection_log.visible = !collection_log.visible

func _on_minimise_pressed() -> void:
	if window_manager:
		window_manager.toggle_minimise()

func _on_strip_toggled(is_minimised: bool) -> void:
	# Hide all HUD content except the minimise button when minimised
	acorn_label.visible = not is_minimised
	shop_button.visible = not is_minimised
	log_button.visible  = not is_minimised
	min_button.text     = "▲" if is_minimised else "▼"

# ── Formatting ────────────────────────────────────────────────────────────────

## Formats large acorn totals nicely: 1234 → "1,234" | 1200000 → "1.2M"
func _format_acorns(n: int) -> String:
	if n >= 1_000_000:
		return "%.1fM 🌰" % (n / 1_000_000.0)
	if n >= 10_000:
		return "%dk 🌰" % (n / 1000)
	# Comma-separate below 10k
	var s := str(n)
	var result := ""
	for i in range(s.length()):
		if i > 0 and (s.length() - i) % 3 == 0:
			result += ","
		result += s[i]
	return result + " 🌰"
